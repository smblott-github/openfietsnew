
europe = /data/osm/europe-latest.osm.pbf
srtm = /data/osm/srtm-alps-uk-ie.pbf

sea = /data/osm/sea.zip
bounds = /data/osm/bounds.zip

tmp = tmp
data = data

id = $(shell cat polygons/$(area).poly.fid )
fid = 21$(id)

build: area                      # This is just to check that the "area" variable is defined."
build: polygons/$(area).poly     # Fetch this from elsewhere.
build: polygons/$(area).poly.fid # Set this to a (unique) two-digit number
build: data/europe.pbf

.PHONY: area
area:
	test -n "$(area)" # "area" must be defined.

# Merge the available OSM and SRTM sources.
data/europe.pbf: $(europe) $(srtm)
	rm -fr $(tmp)
	mkdir -p $(tmp) $(data)
	rm -f $@
	osmosis --read-pbf $(europe) --read-pbf $(srtm) --merge --write-pbf $(tmp)/europe.pbf
	mv -v $(tmp)/europe.pbf $@

austria \
   france \
   germany \
   italy \
   liechtenstein \
   great-britain \
   ireland-and-northern-ireland \
   slovenia \
   switzerland:
	make area=$@ build
