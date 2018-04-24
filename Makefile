
# From Geofabrik.
europe = /data/osm/europe-latest.osm.pbf

# From: http://develop.freizeitkarte-osm.de/ele_20_100_500/.
srtm = /data/osm/Hoehendaten_Freizeitkarte_EUROPE.osm.pbf

# Links for the up-to-date versions of these are here: http://www.openfietsmap.nl/procedure.
sea = /data/osm/sea.zip
bounds = /data/osm/bounds.zip
cities = /data/osm/cities15000.zip

tmp = tmp
data = data
maps = maps

style=openfietsnew
id = $(shell cat polygons/$(area).poly.fid )
fid = 21$(id)

build: area                      # This is just to check that the "area" variable is defined."
build: polygons/$(area).poly     # Fetch this from elsewhere.
build: polygons/$(area).poly.fid # Set this to a (unique) two-digit number
build: data/europe.pbf
build: data/$(area)/pbf
build: data/$(area)/img
build: $(maps)/$(area).img

.PHONY: area
area:
	test -n "$(area)" # "area" must be defined.

# Merge the available OSM and contour sources.
data/europe.pbf: $(europe) $(srtm)
	rm -fr $(tmp)
	mkdir -p $(tmp) $(data)
	rm -f $@
	osmosis --read-pbf file=$(europe) --read-pbf file=$(srtm) --merge --write-pbf file=$(tmp)/europe.pbf omitmetadata=true
	mv -v $(tmp)/europe.pbf $@

# Split the data into tiles for $(area).
data/$(area)/pbf: data/europe.pbf
	rm -fr $(tmp) $@
	mkdir -p $(tmp) $(data)/$(area)
	nice splitter \
	   --max-nodes=1200000                    \
	   --max-areas=1536                       \
           --mapid=$(fid)0001                     \
	   --geonames-file=$(cities)              \
           --description="OSM $(area) $(style)"   \
	   --polygon-file=polygons/$(area).poly   \
	   --precomp-sea=$(sea)                   \
           --output=pbf                           \
           --output-dir=$(tmp)                    \
              $<
	mv -v $(tmp) $@

styles/$(style)/template.args:
	touch styles/$(style)/template.args

# Compile the map tiles.
data/$(area)/img: styles/typ/$(style).typ
data/$(area)/img: $(shell find styles/$(style) -type f)
data/$(area)/img: data/$(area)/pbf
	rm -fr $(tmp) $@
	mkdir -p $(tmp) $(data)/$(area)
	cp styles/typ/$(style).typ $(tmp)/$(style).typ
	gmt -w -y $(fid) $(tmp)/$(style).typ
	nice mkgmap                                     \
	   --output-dir=$(tmp)                          \
	   --read-config=styles/$(style)/template.args   \
	   --precomp-sea=$(sea)                         \
	   --bounds=$(bounds)                           \
           --family-id=$(fid)                            \
	   --area-name=$(area)                          \
	   --country-name=$(area)                       \
	   --gmapsupp                                   \
	   --remove-ovm-work-files                      \
	   --max-jobs=4                                 \
	   --tdbfile                                    \
	   --style-file=styles/$(style)                  \
	   --read-config=data/$(area)/pbf/template.args \
	   $(tmp)/$(style).typ
	mv -v $(tmp) $@

$(maps)/$(area).img: $(data)/$(area)/img
	mkdir -vp $(maps)
	rm -fv $@
	ln -v $</gmapsupp.img $@

countries  =
countries += austria
countries += france
countries += germany
countries += italy
countries += liechtenstein
countries += great-britain
countries += ireland-and-northern-ireland
countries += slovenia
countries += switzerland

all: $(countries)
$(countries):
	make area=$@ build

test ireland:
	make area=ireland-and-northern-ireland

.PHONY: all $(countries) test ireland
