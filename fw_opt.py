
FIRMWARE_FILE_NAME = "blink_led0.dat"
DIGEST_FILE_NAME = "blink_led0_dat.digest"
CRC16_START_VAL = 0xffff

# FW data offsets
NUMBER_COMPONENT_OFFSET = 55
COMPONENT_TYPE_OFFSET = 50
HEADER_SIZE_OFFSET = 24
IMAGE_SIZE_OFFSET = 25

# FW block id
NUMBER_OF_BLOCKS_ID = 5
DATASTREAM_ID = 8

# FW data length
NUMBER_COMPONENT_BYTE_LENGTH = 2
HEADER_SIZE_BYTE_LENGTH = 1
IMAGE_SIZE_BYTE_LNEGTH = 4
BTYES_PER_TABLE_RECORD = 9

# other consts
BLOCK_SIZE = 16
DIGEST_SIZE = 32

# component types
COMP_BITS = 0
COMP_FPGA = 1
COMP_KEYS = 2
COMP_SNVM = 3
COMP_ENVM = 6
COMP_OWP  = 7
COMP_EOB  = 127
typesDict = {'BITS': 	COMP_BITS,
		 	 'Fabric': 	COMP_FPGA,
			 'sNVM' : 	COMP_SNVM,
			 'EOB' : 	COMP_EOB}

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

def getBlockOffset(blockID, file):
	# get number of blocks
	file.seek(HEADER_SIZE_OFFSET)
	headerSize = int.from_bytes(file.read(HEADER_SIZE_BYTE_LENGTH), 'little')

	file.seek(headerSize-1)
	blockNum = int.from_bytes(file.read(1), 'little')

	for i in range(blockNum):
		file.seek(headerSize + i*BTYES_PER_TABLE_RECORD)
		currID = int.from_bytes(file.read(1), 'little')
		if currID == blockID:
			return int.from_bytes(file.read(4), 'little') # return addres offset of req block

	return -1


digests = {}

# read digests
with open(DIGEST_FILE_NAME, 'r') as digestFile:
	for line in digestFile:
		words = line.split()
		if words[0] in typesDict:
			digests[typesDict[words[0]]] = words[4] #bytearray.fromhex(words[4])
		else:
			print("Wrong type component, update typesDict, comp = ", words[0])
print(digests)


# prepare firmware
fwFile = open(FIRMWARE_FILE_NAME, 'rb')
imageFile = open('image_'+FIRMWARE_FILE_NAME, 'wb')


# get number of component
fwFile.seek(NUMBER_COMPONENT_OFFSET)
compNum = int.from_bytes(fwFile.read(NUMBER_COMPONENT_BYTE_LENGTH), 'little')


# get sizes of component
compSize = []
numOfcompOffset = getBlockOffset(NUMBER_OF_BLOCKS_ID, fwFile)
print('numOfcompOffset = ', numOfcompOffset)

for i in range(compNum):
	fwFile.seek(numOfcompOffset + (i * 22) // 8)
	temp = int.from_bytes(fwFile.read(4), 'little')
	temp >>= (i * 22) % 8
	temp &= 0x3FFFFF
	compSize.append(temp)


# === IMAGE STRUCTURE ===
# ======== HEADER ==========
# Image size 			- 4B
# Number of components 	- 2B
# Size of component 1 	- 4B
# ...
# Size of component N 	- 4B
# header CRC16 			- 2B
# ==========================

# ====== Data section ======
# Data of component 1 	- ?B
# Digest of component 1 - 32B
# ...
# Data of component N 	- ?B
# Digest of component N - 32B
# ===========================

# ==========================
# Image CRC 16 			- 2B
# ==========================

#=================================== Write image =================================
# create image CRC
imageCRC = CRC16_START_VAL

# calc image size
imageSize = 4 + 2 + 4*compNum + 2 + 2
for component in range(compNum):
	imageSize += compSize[component]*BLOCK_SIZE + DIGEST_SIZE
	print('Size of component #' + str(component) + ' = ' + str(compSize[component]))

#writeHeader
imageFile.write(imageSize.to_bytes(4, 'little'))
imageCRC = calc_crc(imageCRC, imageSize, 4)

imageFile.write(compNum.to_bytes(2, 'little'))
imageCRC = calc_crc(imageCRC, compNum, 2)

for size in compSize:
	imageFile.write(size.to_bytes(4, 'little'))
	imageCRC = calc_crc(imageCRC, size, 4)

# write header CRC
imageFile.write(imageCRC.to_bytes(2, 'little')) 
imageCRC = calc_crc(imageCRC, imageCRC, 2)


# write components and digests
dataStreamOffset = getBlockOffset(DATASTREAM_ID, fwFile)

dataIdx = 0 # index of byte within datastream block

for component in range(compNum):
	fwFile.seek(dataStreamOffset + dataIdx + COMPONENT_TYPE_OFFSET)
	compType = int.from_bytes(fwFile.read(1), 'little')

	#write component
	fwFile.seek(dataStreamOffset + dataIdx)
	for block in range(compSize[component]):
		# write block to image
		blockData = fwFile.read(BLOCK_SIZE)
		imageFile.write(blockData)
		dataIdx += BLOCK_SIZE

		#calc crc of block
		for byte in bytearray(blockData):
			imageCRC = calc_crc(imageCRC, byte)

	#write component digest
	if compType in digests:
		digest = bytearray.fromhex(digests[compType])
		digest.reverse()
		imageFile.write(digest)
		#print(digest)

		#calc CRC of digest
		for byte in digest:
			if(component == compNum-1):
				print("Digest byte = ", hex(byte))
			imageCRC = calc_crc(imageCRC, byte)			

	else:
		print('No digest found for component #', component, ' component type = ', compType)
		break


# write image CRC
imageFile.write(imageCRC.to_bytes(2, 'little'))


imageFile.close()
fwFile.close()
print('Done')

input()
