# Convert.sh
# Uses cjpeg (https://github.com/kornelski/mozjpeg/releases) to convert a folder of
# unmodified original images into progressive JPEG

for FILENAME in *.jpg; do
	echo $FILENAME
	../cjpeg/cjpeg -quant-table 2 -quality 70 -outfile "../converted/$FILENAME" $FILENAME
done

