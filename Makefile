
europe = /data/osm/europe-latest.osm.pbf
srtm = /data/osm/srtm-alps-uk-ie.pbf

sea = /data/osm/sea.zip
bounds = /data/osm/bounds.zip
cities = /data/osm/cities15000.zip

tmp = tmp
data = data

style=openfietsnew
id = $(shell cat polygons/$(area).poly.fid )
fid = 21$(id)

build: area                      # This is just to check that the "area" variable is defined."
build: polygons/$(area).poly     # Fetch this from elsewhere.
build: polygons/$(area).poly.fid # Set this to a (unique) two-digit number
build: data/europe.pbf
build: data/$(area)/pbf

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

data/$(area)/pbf: data/europe.pbf
	rm -fr $(tmp) $@
	mkdir -p $(tmp) $(data)/$(area)
	nice splitter \
	   --max-nodes=850000                     \
	   --max-nodes=1600000                    \
           --mapid=$(fid)0001                     \
	   --geonames-file=$(cities)              \
           --description="OSM $(area) $(style)"   \
	   --polygon-file=polygons/$(area).poly   \
           --output=pbf                           \
           --output-dir=$(tmp)                    \
              $<
	mv -v $(tmp) $@

style/$(style)/template.args:
	touch style/$(style)/template.args

data/$(area)/img: style/$(style)/template.args
data/$(area)/img: data/$(area)/pbf
	rm -fr $(tmp) $@
	mkdir -p $(tmp) $(data)/$(area)
	cp style/typ/$(style).typ $(tmp)/$(style).typ
	gmt -w -y $(fid) $(tmpdir)/$(style).typ
	nice mkgmap                                     \
	   --output-dir=$(tmp)                          \
	   --read-config=style/$(style)/template.args   \
	   --precomp-sea=$(sea)                         \
	   --bounds=$(bounds)                           \
           --family-id=$(ml)                            \
	   --area-name=$(area)                          \
	   --country-name=$(area)                       \
	   --gmapsupp                                   \
	   --max-jobs                                   \
	   --style-file=style/$(style)                  \
	   --read-config=data/$(area)/pbf/template.args \
	   $(tmp)/$(style).typ
	mv -v $(tmp) $@

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
