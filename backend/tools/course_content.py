def build_course(blobs,parse,items):
 tables={n:parse(blobs['data/tables/object_'+n+'.lua'].data)for n in ['subject','class','book','book_color','branch','book_shop','log']}
 def vec(s):return [int(x)for x in s.split('|')if x and x!='0']
 misc={r['key']:r['value']for r in parse(blobs['data/tables/misc.lua'].data)}
 classes={int(r['id']):r for r in tables['class']};tickets={int(r['id']):int(classes[int(r['class_type'])]['application'])for r in tables['book']}
 qualities=sorted(tables['book_color'],key=lambda r:int(r['id']))
 refunds={int(r['id']):dict(zip(vec(r['book_return']),vec(r['book_numb'])))for r in qualities}
 itemmap={int(r['id']):r for r in items};books=vec(misc['object_box_books']);bookexp={i:int(itemmap[i]['proficiency'])for i in books}
 levels=parse(blobs['data/tables/skill_level.lua'].data);assert len(levels)==6
 out=dict(schema_version=1,policy_id='C2E_V1_COURSE_PROGRESS_AND_SEEDS_V1',overflow_policy_id='C2E_V1_WHOLE_BOOK_PROFICIENCY_V1',tables=tables,Duration=int(misc['object_classroom_time']),ForgetCost=int(misc['object_class_forget']),SpeedHalfHour=int(misc['object_classroom_money'])//2,MaxEXP=int(misc['object_max_proficiency']),LogLimit=int(misc['object_classroom_log_limit']),Tickets=tickets,BookEXP=bookexp,Capacity={int(r['id']):int(r['num_study'])for r in parse(blobs['data/tables/vip.lua'].data)},Thresholds=[int(r['total_proficiency'])for r in qualities],Refunds=refunds,Slots=[r['book_open']=='1'for r in levels])
 # JSON object identities are strings before canonical hashing; mixed-width VIP keys must sort lexically.
 for key in ['Tickets','BookEXP','Capacity','Refunds']:
  out[key]={str(k):({str(i):n for i,n in v.items()}if isinstance(v,dict)else v)for k,v in out[key].items()}
 assert len(tables['book'])==48 and out['Thresholds']==[0,90,240,480,930,1680] and list(bookexp.values())==[10,50,250,1250]
 return out
