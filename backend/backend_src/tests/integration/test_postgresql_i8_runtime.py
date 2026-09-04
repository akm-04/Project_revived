from __future__ import annotations
import json
import os
import re
from uuid import uuid4

import pytest
from sqlalchemy import select, update

from gxb_backend.app_factory import create_app
from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.migration.schema import migration_runs
from gxb_backend.mail.models import MailDeliveryIntent
from gxb_backend.mail.repository import MailRepository
from gxb_backend.runtime.authority import RuntimeAuthorityError, RuntimeAuthorityRepository
from gxb_backend.runtime.composition import create_postgres_app

pytestmark = pytest.mark.postgresql
_SAFE_DATABASE = re.compile(r"^[a-z_][a-z0-9_]{0,62}(?:test|_test)$")


def configured(monkeypatch):
    url=os.environ.get("GXB_TEST_DATABASE_URL","")
    if not url: pytest.skip("GXB_TEST_DATABASE_URL not configured")
    settings=DatabaseSettings.from_env({"GXB_DATABASE_URL":url})
    assert _SAFE_DATABASE.fullmatch(settings.url.database or "")
    monkeypatch.setenv("GXB_DATABASE_URL",url); monkeypatch.setenv("GXB_HTTP_WORKERS","1")
    return settings


def test_traffic_open_is_database_irreversible(monkeypatch):
    settings=configured(monkeypatch); provider=ProcessEngineProvider(settings)
    try:
        with provider.engine().connect() as connection: RuntimeAuthorityRepository().require_postgresql(connection)
        with pytest.raises(Exception):
            with provider.engine().begin() as connection: connection.execute(update(migration_runs).where(migration_runs.c.status=="TRAFFIC_OPEN").values(status="VALIDATED"))
    finally: provider.dispose()


def test_legacy_json_launcher_refuses_after_open(monkeypatch):
    configured(monkeypatch)
    with pytest.raises(RuntimeAuthorityError): create_app()


def test_stock_like_mid18_mid1_mid17_and_ready(monkeypatch):
    configured(monkeypatch); client=create_postgres_app().test_client()
    identity=client.post('/server/mobile_api_new/',json={'mid':65284,'payload':{'device_id':'pytest-i8'}}).get_json()
    def post(body): return client.post('/api/v1',data={'payload':json.dumps(body,separators=(',',':'))}).get_json()
    regions=post({'mid':18,'sid':identity['sid'],'login_token':identity['token'],'request_id':'pytest-i8-18'})
    boot=post({'mid':1,'sid':identity['sid'],'login_token':identity['token'],'region':125,'request_id':'pytest-i8-1','client_op_id':'pytest-i8-op'})
    player=post({'mid':17,'token':boot['token'],'region':125,'request_id':'pytest-i8-17'})
    settings=DatabaseSettings.from_env({'GXB_DATABASE_URL':os.environ['GXB_TEST_DATABASE_URL']}); provider=ProcessEngineProvider(settings)
    mail_id=800000 + (uuid4().int % 100000000)
    delivery_key=f'pytest-i8-mail-{uuid4().hex}'
    try:
        with provider.engine().begin() as connection:
            MailRepository().deliver(connection,MailDeliveryIntent(player_id=int(player['player_id']),delivery_key=delivery_key,source_type='TEST',source_id=delivery_key,protocol_payload={'title':'I8'},protocol_mail_id=mail_id))
    finally: provider.dispose()
    listed=post({'mid':368,'token':boot['token'],'region':125,'request_id':'pytest-i8-368'})
    read=post({'mid':369,'token':boot['token'],'region':125,'id':mail_id,'is_region':0,'request_id':'pytest-i8-369'})
    claimed=post({'mid':370,'token':boot['token'],'region':125,'normal_ids':[mail_id],'region_ids':[],'request_id':'pytest-i8-370','client_op_id':f'pytest-i8-mail-op-{mail_id}'})
    ready=client.get('/health/ready').get_json()
    assert regions['error_code']==boot['error_code']==player['error_code']==0
    assert boot['token'] != identity['token']
    assert any(row['id']==mail_id for row in listed['mail_list']) and read['changed'] is True
    assert next(row for row in claimed['mail_list']['mail_list'] if row['id']==mail_id)['is_awarded']==1
    assert ready['authority']=='TRAFFIC_OPEN' and ready['http_workers']==1 and ready['legacy_rlock_retained'] is False
    assert ready['status']=='ready' and ready['maintenance_active'] is False
