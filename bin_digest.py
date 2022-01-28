DIGEST_FILE_NAME = "blink_led0_dat.digest"

digestBin = open('binary_digest.bin', 'wb');

with open(DIGEST_FILE_NAME, 'r') as digestFile:
	for line in digestFile:
		words = line.split()
		digest = bytearray.fromhex(words[4])
		digest.reverse()
		digestBin.write(digest)

digestBin.close()