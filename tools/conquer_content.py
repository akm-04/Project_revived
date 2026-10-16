def build_conquer(blobs,parse,parse_indexed,field):
 return dict(schema_version=1,policy_id='C2J_CONQUER_SOURCE_V1',tables={key:parse(blobs['data/tables/'+name+'.lua'].data)for key,name in [('regions','conquer_school'),('campaigns','conquer_school_campaign'),('loops','conquer_school_loop')]})
