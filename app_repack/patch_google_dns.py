"""Makes XinydUtils.getGoogleDNS return the given host (the DNS bypass decompile_and_patch.sh does inline).
usage: patch_google_dns.py <XinydUtils.smali> <host>
"""
import sys

path, host = sys.argv[1], sys.argv[2]
content = open(path).read()
head, marker, tail = content.partition('.method public static getGoogleDNS(')
assert marker, 'getGoogleDNS not found'
_, end, rest = tail.partition('.end method')
assert end, 'getGoogleDNS has no .end method'
body = f')Ljava/lang/String;\n    .registers 1\n\n    const-string v0, "{host}"\n\n    return-object v0\n'
open(path, 'w').write(head + marker + body + end + rest)
print('patched getGoogleDNS ->', host)
