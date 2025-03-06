extends SceneTree

func _init() -> void:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	
	if not main(arguments):
		quit(1)
	else:
		quit()

func main(arguments: Dictionary) -> bool:
	if not arguments.has('input'):
		print ("Must pass input file as --input=FILENAME")
		return false
	
	if not arguments.has('output'):
		print ("Must pass output file as --output=FILENAME")
		return false

	return log2json(arguments['input'], arguments['output'])

func log2json(input_filename: String, output_filename: String) -> bool:
	if not FileAccess.file_exists(input_filename):
		print("No such input file: %s" % input_filename)
		return false
	var infile := FileAccess.open_compressed(input_filename, FileAccess.READ, FileAccess.COMPRESSION_FASTLZ)
	if not infile:
		print("Unable to open input file: %s" % input_filename)
		return false

	var outfile := FileAccess.open(output_filename, FileAccess.WRITE)
	if not outfile:
		infile.close()
		print("Unable to open output file: %s" % output_filename)
		return false

	while not infile.eof_reached():
		var data = infile.get_var()
		outfile.store_line(JSON.stringify(data))
	
	infile.close()
	outfile.close()
	
	return true
