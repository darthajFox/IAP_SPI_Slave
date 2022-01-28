
IMAGE_FILE_NAME = "image_blink_led0.dat"

BLOCK_SIZE = 32768	 # 0x8000
CRC16_START_VAL = 0xffff

imageFile = open(IMAGE_FILE_NAME, 'rb')
tpImageFile = open('tp_'+IMAGE_FILE_NAME, 'wb')
infoImageFile = open('info_'+IMAGE_FILE_NAME, 'w')


def calc_crc(crc, data, bytes=1):
	for i in range(bytes):
		for j in range(8):
			if (data ^ crc) & 0x01:
				crc >>= 1
				crc ^= 0x8408
			else:
				crc >>= 1

			data >>= 1

	return crc

# get image size
imageFile.seek(0, 2)
imageSize = imageFile.tell()
imageFile.seek(0)

numOfblock = imageSize // BLOCK_SIZE
lastBlockSize = imageSize % BLOCK_SIZE

infoImageFile.write('Original image size = ' + str(imageSize) + '\n')
infoImageFile.write('Number of blocks = ' + str(numOfblock+1) + '\n')
infoImageFile.write('Block size = ' + str(BLOCK_SIZE) + '\n')
infoImageFile.write('Last block size = ' + str(lastBlockSize) + '\n')
print('Image size = ', imageSize)

# create image CRC
imageCRC = CRC16_START_VAL

# process blocks
for block in range(numOfblock):

	blockData = imageFile.read(BLOCK_SIZE)
	tpImageFile.write(blockData)

	#create block CRC
	blockCRC = CRC16_START_VAL

	for byte in blockData:
		blockCRC = calc_crc(blockCRC, byte)
		imageCRC = calc_crc(imageCRC, byte)

	tpImageFile.write(blockCRC.to_bytes(2, 'little'))
	# imageCRC = calc_crc(imageCRC, blockCRC, 2)	

	infoImageFile.write('Block #' + str(block ) + ', size  = ' + str(BLOCK_SIZE) + ', CRC16 = ' + hex(blockCRC) + ', image CRC16 = ' + hex(imageCRC) + '\n')

# process last block
blockData = imageFile.read(lastBlockSize)
tpImageFile.write(blockData)

blockCRC = CRC16_START_VAL
for byte in blockData:
	blockCRC = calc_crc(blockCRC, byte)
	imageCRC = calc_crc(imageCRC, byte)
	#print(imageCRC)

tpImageFile.write(blockCRC.to_bytes(2, 'little'))
#imageCRC = calc_crc(imageCRC, blockCRC, 2)

infoImageFile.write('Last block size  = ' + str(lastBlockSize) + ', CRC16 = ' + hex(blockCRC) + '\n')
infoImageFile.write('Image CRC16 = ' + hex(imageCRC))

imageFile.close()
tpImageFile.close()
infoImageFile.close()
print('Done')

input()
