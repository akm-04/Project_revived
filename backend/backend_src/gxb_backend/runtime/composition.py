"""I9 process-local, multi-worker-safe production compositions."""
from __future__ import annotations

import os

from flask import Flask, jsonify

from gxb_backend.config import SETTINGS, Settings
from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.foundation.database import ProcessEngineProvider
from gxb_backend.identity.locking import register_i3_identity_lockers
from gxb_backend.identity.service import AccountSessionAuthenticator, ContextSelectionService, GameplayContextAuthenticator, IdentityService, RegionDirectoryService
from gxb_backend.mail.locking import register_i6_mail_lockers
from gxb_backend.observability.resource_gateway import ResourceGateway
from gxb_backend.persistence.locking import register_i4_persistence_lockers
from gxb_backend.persistence.repositories import PostgresPlayerAggregateRepository
from gxb_backend.projections.outbox import ProjectionOutboxWorker
from gxb_backend.realtime import RealtimeRuntime
from gxb_backend.realtime.control import RealtimeControlPublisher
from gxb_backend.realtime.durable import RealtimeControlEventHandler, RealtimeOutboxDispatcher
from gxb_backend.realtime.gateway import RealtimeGateway, RealtimeGatewaySettings
from gxb_backend.realtime.liveness import RealtimeLivenessSweeper
from gxb_backend.realtime.wakeup import PsycopgOutboxWakeupListener
from gxb_backend.scheduler.runtime import SchedulerProcess
from gxb_backend.scheduler.worker import SchedulerSettings, SchedulerWorker
from gxb_backend.transactions import OutboxRepository, ResourceLockRegistry, ResourceTransactionCoordinator, ScheduledJobRepository
from gxb_backend.transport.routes_commerce import register_commerce_routes
from gxb_backend.transport.routes_engine import register_engine_routes
from gxb_backend.transport.routes_sdk import register_sdk_routes

from .authority import RuntimeAuthorityRepository
from .config import ProductionRuntimeSettings
from .maintenance import MaintenanceGate, MaintenanceGatedSchedulerProcess
from .state_repository import PostgresStateRepository


def _kernel(runtime: ProductionRuntimeSettings):
    provider = ProcessEngineProvider(runtime.database)
    with provider.engine().connect() as connection:
        RuntimeAuthorityRepository().require_service_start(connection,maintenance_active=runtime.maintenance_active)
    locks = register_i6_mail_lockers(register_i4_persistence_lockers(register_i3_identity_lockers(ResourceLockRegistry())))
    outbox = OutboxRepository()
    jobs = ScheduledJobRepository()
    coordinator = ResourceTransactionCoordinator(provider.engine, lock_registry=locks, outbox_repository=outbox, job_repository=jobs)
    account_auth = AccountSessionAuthenticator(provider.engine, coordinator, policy=runtime.identity_policy)
    identity = IdentityService(provider.engine, coordinator, policy=runtime.identity_policy)
    context_auth = GameplayContextAuthenticator(provider.engine, coordinator, policy=runtime.identity_policy)
    aggregates = PostgresPlayerAggregateRepository()
    selection = ContextSelectionService(
        provider.engine, coordinator, account_auth,
        player_materialized_probe=aggregates.is_materialized,
    )
    regions = RegionDirectoryService(provider.engine, coordinator, account_auth)
    return provider, coordinator, outbox, jobs, identity, account_auth, context_auth, selection, regions, aggregates


def create_postgres_state(*, settings: Settings = SETTINGS, runtime: ProductionRuntimeSettings | None = None):
    runtime = runtime or ProductionRuntimeSettings.from_env()
    parts = _kernel(runtime)
    provider, coordinator, _, _, identity, account_auth, context_auth, selection, regions, aggregates = parts
    maintenance_gate=MaintenanceGate(runtime.maintenance_file)
    state = PostgresStateRepository(
        data_path=settings.player_db_path, profile=settings.profile, engine_provider=provider.engine,
        coordinator=coordinator, identity=identity, account_auth=account_auth,
        context_auth=context_auth, context_selection=selection, region_directory=regions,
        player_repository=aggregates, anonymous_account_uid=runtime.anonymous_account_uid,
        maintenance_gate=maintenance_gate,
    )
    return state, provider, parts


def create_postgres_app(*, settings: Settings = SETTINGS, runtime: ProductionRuntimeSettings | None = None) -> Flask:
    runtime = runtime or ProductionRuntimeSettings.from_env()
    state, provider, _ = create_postgres_state(settings=settings, runtime=runtime)
    app = Flask(__name__)
    app.config["JSON_SORT_KEYS"] = False
    resources = ResourceGateway(settings)
    realtime_facade = RealtimeRuntime(settings.chat_host, settings.chat_port, state)
    dispatcher = EngineDispatcher(state, settings, resources, post_commit_sink=None, realtime_runtime=realtime_facade)
    register_sdk_routes(app, state)
    register_commerce_routes(app, state)
    register_engine_routes(app, dispatcher, settings, resources)

    @app.get("/health/live")
    def health_live(): return jsonify({"status": "live", "process": "http", "pid": os.getpid()})

    @app.get("/health/ready")
    def health_ready():
        probe = provider.probe()
        with provider.engine().connect() as connection:
            authority=RuntimeAuthorityRepository().require_service_start(connection,maintenance_active=runtime.maintenance_active)
        return jsonify({"status":"maintenance_ready" if runtime.maintenance_active else "ready","authority":authority["authority"],"maintenance_active":runtime.maintenance_active,"database":probe["database"],"isolation":probe["isolation"],"http_workers":runtime.http_workers,"legacy_rlock_retained":False,"max_proven_http_workers":4,"pid":os.getpid()})

    app.extensions.update(gxb_state=state, gxb_dispatcher=dispatcher, gxb_resource_gateway=resources, gxb_realtime_runtime=realtime_facade, gxb_engine_provider=provider)
    return app


def create_realtime_gateway(*, settings: Settings = SETTINGS, runtime: ProductionRuntimeSettings | None = None) -> tuple[RealtimeGateway, ProcessEngineProvider]:
    runtime = runtime or ProductionRuntimeSettings.from_env(application_name="gxb-realtime")
    state, provider, parts = create_postgres_state(settings=settings, runtime=runtime)
    outbox = parts[2]
    transient = RealtimeRuntime(settings.chat_host, settings.chat_port, state)
    controls = RealtimeControlPublisher(transient.session_registry)
    dispatcher = RealtimeOutboxDispatcher(provider.engine, transient.publisher, RealtimeControlEventHandler(controls), repository=outbox)
    sweeper = RealtimeLivenessSweeper(provider.engine, transient.session_registry, controls, policy=runtime.identity_policy)
    wakeup_url = runtime.database.url.set(drivername="postgresql").render_as_string(hide_password=False)
    wakeup = PsycopgOutboxWakeupListener(wakeup_url)
    gate=MaintenanceGate(runtime.maintenance_file)
    gateway=RealtimeGateway(transient.server,dispatcher,sweeper,wakeup=wakeup,settings=RealtimeGatewaySettings(),paused=gate.active)
    return gateway, provider


def create_scheduler_process(*, runtime: ProductionRuntimeSettings | None = None) -> tuple[SchedulerProcess, ProcessEngineProvider]:
    runtime = runtime or ProductionRuntimeSettings.from_env(application_name="gxb-scheduler")
    provider, _, outbox, jobs, *_ = _kernel(runtime)
    # No autonomous gameplay job type is active in the current bounded
    # foundation. Unknown durable rows fail closed and enter retry/dead policy.
    scheduler = SchedulerWorker(provider.engine, jobs, SchedulerSettings(worker_id="gxb-scheduler"), handlers={})
    projections = ProjectionOutboxWorker(provider.engine, handlers={}, repository=outbox, worker_id="gxb-projection")
    return MaintenanceGatedSchedulerProcess(SchedulerProcess(scheduler,projections),MaintenanceGate(runtime.maintenance_file)),provider
