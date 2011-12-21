When /^client specifies a Volume Configuration$/ do |volume_config|
  header 'Accept', 'application/xml'
  authorize 'mockuser', 'mockpassword'
  get volume_config.raw[0][1]
  last_response.status.should==200
  @volume_config = CIMI::Model::VolumeConfiguration.from_xml(last_response.body)
  @volume_config.class.should == CIMI::Model::VolumeConfiguration
  @volume_config.attribute_values[:capacity].quantity.should == "2"
  @volume_config.uri.should == volume_config.raw[0][1]
end

When /^client specifies a new Volume using$/ do |volume|
  @volume_config.should_not be_nil
  volume_name = volume.raw[0][1]
  volume_description = volume.raw[1][1]
  @builder = Nokogiri::XML::Builder.new do |xml|
    xml.Volume(:xmlns => CMWG_NAMESPACE) {
      xml.name volume_name
      xml.description volume_description
      xml.volumeTemplate {
        xml.volumeConfig( :href => @volume_config.uri )
      }
    }
  end
end

Then /^client should be able to create this Volume$/ do
  authorize 'mockuser', 'mockpassword'
  header 'Content-Type', 'application/xml'
  post '/cimi/volumes', @builder.to_xml
  last_response.status.should == 200
  @@created_volume = CIMI::Model::Volume.from_xml(last_response.body)
end

When /^client GET the Volumes Collection$/ do
  authorize 'mockuser', 'mockpassword'
  header 'Content-Type', 'application/xml'
  get "/cimi/volumes"
  last_response.status.should == 200
  @@volume_collection = VolumeCollection.from_xml(last_response.body)
end

Then /^client should get a list of volumes$/ do
  @@volume_collection.uri.end_with?("/cimi/volumes").should == true
  @@volume_collection.attribute_values.has_key?(:volumes).should == true
end

Then /^list of volumes should contain newly created volume$/ do
  volumes = @@volume_collection.attribute_values[:volumes].map{|v| v.href.split("/").last}
  volumes.include?(@@created_volume.name).should == true
end

When /^client GET the newly created Volume in json format$/ do
  authorize 'mockuser', 'mockpassword'
  get "/cimi/volumes/#{@@created_volume.name}?format=json"
  last_response.status.should == 200
  @@retrieved_volume = CIMI::Model::Volume.from_json(last_response.body)
end

Then /^client should verify that this Volume was created correctly$/ do |capacity|
  @@retrieved_volume.name.should == @@created_volume.name
  @@retrieved_volume.uri.should == @@created_volume.uri
  @@retrieved_volume.capacity[:quantity].should == capacity.raw[0][1]
end

When /^client deletes the newly created Volume$/ do
  authorize 'mockuser', 'mockpassword'
  delete "/cimi/volumes/#{@@created_volume.name}"
  last_response.status.should == 200
end

Then /^client should verify the volume was deleted$/ do
  authorize 'mockuser', 'mockpassword'
  get "/cimi/volumes/#{@@created_volume.name}"
  last_response.status.should == 404
end
