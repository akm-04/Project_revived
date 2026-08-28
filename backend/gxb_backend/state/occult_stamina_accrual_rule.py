"""Pass211 derived rule: canonical stamina debits accrue Sorcery War tickets."""
from __future__ import annotations
from dataclasses import replace
from gxb_backend.content.occult_source_catalog import OccultSourceCatalog
from .derived_mutation_rules import DerivedMutationContext
from .mutation_plan import EntityMutation, MutationPlan, TemporalTransition

class OccultStaminaAccrualRule:
    name='occult_stamina_accrual'
    def __init__(self,source:OccultSourceCatalog)->None:self.source=source
    def augment(self,plan:MutationPlan,context:DerivedMutationContext)->MutationPlan:
        spent=0
        for op in plan.operations:
            if isinstance(op,TemporalTransition) and str(op.resource_key)=='energy' and str(op.action).upper()=='DEBIT':
                try: amount=int(op.amount)
                except (TypeError,ValueError): amount=0
                if amount>0: spent+=amount
        if spent<=0:return plan
        return replace(plan,operations=tuple(plan.operations)+(EntityMutation('OCCULT',1,'ACCRUE_ENERGY',amount=spent),))
