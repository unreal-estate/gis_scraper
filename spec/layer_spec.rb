require 'layer'

describe Layer do

  let(:feature_layer) { Layer.new 'http://gps.digimap.gg/arcgis/rest/services/StatesOfJersey/JerseyMappingOL/MapServer/0' }
  let(:group_layer) { Layer.new('http://gps.digimap.gg/arcgis/rest/services/JerseyUtilities/JerseyUtilities/MapServer/146', __dir__) }
  let(:no_layer_id_url) { Layer.new 'no/layer/number/specified/MapServer' }
  let(:not_map_server_url) { Layer.new '"MapServer"/missing/42' }
  let(:feature_layer_with_path) { Layer.new('http://gps.digimap.gg/arcgis/rest/services/StatesOfJersey/JerseyPlanning/MapServer/11', __dir__) }
  let(:layer_with_sub_group_layers) { Layer.new 'http://gps.digimap.gg/arcgis/rest/services/JerseyUtilities/JerseyUtilities/MapServer/129', __dir__ }
  sub_layers = [{"id"=>130, "name"=>"High Pressure"}, {"id"=>133, "name"=>"Medium Pressure"}, {"id"=>136, "name"=>"Low Pressure"}]

  let(:scraper_double) { instance_double 'FeatureScraper' }

  context '#new(url)' do
    it 'raises ArgumentError "URL must end with layer id" with a URL not ending in an integer' do
      expect(->{no_layer_id_url}).to raise_error ArgumentError, 'URL must end with layer id'
    end

    it 'raises ArgumentError "Bad MapServer URL" with a URL not ending in an integer' do
      expect(->{not_map_server_url}).to raise_error ArgumentError, 'Bad MapServer URL'
    end

    it 'instantiates an instance of the class with no second arg' do
      expect(feature_layer.class).to eq Layer
    end
  end

  context '#validate_type' do
    it 'raises UnknownLayerType <type> if layer type is not in TYPES' do
      expect(->{feature_layer.validate_type('Unknown Layer')}).to raise_error Layer::UnknownLayerType, 'Unknown Layer'
    end
  end

  context '#type' do
    it 'returns the layer type for a feature layer' do
      expect(feature_layer.type).to eq 'Feature Layer'
    end

    it 'returns the layer type for a group layer' do
      expect(group_layer.type).to eq 'Group Layer'
    end
  end

  context '#sub_layer_id_names' do
    it 'returns an empty list for a feature layer (which have no sub layers)' do
      expect(feature_layer.sub_layer_id_names).to eq []
    end

    it 'returns a list of the sublayer hashes for :id, :name for a group layer, if any' do
      expect(layer_with_sub_group_layers.sub_layer_id_names).to eq sub_layers
    end
  end

  context '#write_feature_files(name, id)' do
    it "writes a feature layer's data to a JSON file in the path specified or '.'" do
      file_name = 'Aircraft Noise Zone 1.json'
      layer = feature_layer_with_path
      begin
        layer.write_feature_files(layer.name, layer.id)
        expect(`ls ./spec`).to include file_name
      ensure
        File.delete File.new(File.join __dir__, file_name) rescue nil # cleanup
      end
    end
  end

  context '#sub_layer(id)' do
    it 'returns the a Layer object for the given the sub layer id' do
      expect(layer_with_sub_group_layers.sub_layer(130, __dir__).class). to eq Layer
    end
  end

  context '#write' do
    it 'calls #write_feature_files for a feature layer' do
      layer = feature_layer
      allow(layer).to receive(:write_feature_files)
      expect(->{layer.write}).not_to raise_error
    end

    it "creates sub directories mirroring sub-group structure" do
      dir_names = ['High Pressure', 'Medium Pressure', 'Low Pressure']
      allow_any_instance_of(Layer).to receive :write_feature_files # stub recursive instances, so nothing is scraped!!
      begin
        layer_with_sub_group_layers.write
        dir_names.all? { |dir| expect(`ls ./spec`).to include dir }
      ensure
        dir_names.each { |dir_name| FileUtils.rm_rf "#{__dir__}/#{dir_name}" rescue nil } # cleanup
      end
    end
  end

end
