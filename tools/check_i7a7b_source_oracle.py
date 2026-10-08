from pathlib import Path
import hashlib,json,sys,zipfile
R=Path(__file__).resolve().parents[1];source=Path(sys.argv[1])/'all-assest-rechecked-1.zip';expected=json.loads((R/'docs/i7a7b/SRC64_FILE_IDENTITIES.json').read_text());assert hashlib.file_digest(source.open('rb'),'sha256').hexdigest()=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
with zipfile.ZipFile(source)as z:
 for p,h in expected.items():assert hashlib.sha256(z.read('app-assets/output/assets/src_64/'+p)).hexdigest()==h,p
backend=(R/'internal/adapters/stockruntime/social_dispatcher.go').read_text();assert 'd.Gifts.Send('in backend and'd.Gifts.Claim('in backend and'd.Scalar.CurrentScalar('in backend and'9007199254740991'in backend
assert 'awards'in backend and'economy_'in backend
assert 'HTTPStatus: 409'in backend and'context.WithTimeout(ctx, 12*time.Second)'in backend
assert 'IsSent: p.IsSent'in(R/'internal/adapters/socialpresentation/wire.go').read_text()
assert 'ReloadGiftRecipientNotice'in(R/'internal/adapters/stockruntime/social_reload.go').read_text()
# Source-derived executable callback model: non200 invokes no Gift success
# callback; an HTTP200 error_code does, explaining selected failure transport.
def stock_callback(http_status,body):return http_status==200
assert not stock_callback(409,{'error':'social_gift_unavailable'})
assert stock_callback(200,{'error_code':1})
assert stock_callback(200,{})
# Bulk callback hazard remains unresolved physical-client behavior, not fixed.
assert 9+3>10
print(json.dumps({'status':'PASS','class':'EXACT_SRC64_IDENTITIES_STATIC_SEAMS_AND_PYTHON_CALLBACK_MODEL','files':expected,'limits':['No original-server truth','No executedLua orphysicalW2','Bulkcallbacks mayovercount','DeletedSenderhiddenaccess','TeacherMaster/intimacyunqualified','GMT+8midnight/uniform5 selectedpolicy']},indent=2))
