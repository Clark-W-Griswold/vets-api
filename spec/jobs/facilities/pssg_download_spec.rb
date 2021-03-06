# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Facilities::PSSGDownload, type: :job do
  let(:drive_time_data_648A4) do
    fixture_file_name = "#{::Rails.root}/spec/fixtures/pssg/drive_time_data_648A4.json"
    File.open(fixture_file_name, 'rb') do |f|
      JSON.parse(f.read)
    end
  end

  let(:drive_time_data_648A4_no_rings) do
    bands = drive_time_data_648A4
    bands.first['geometry']['rings'] = []
    bands
  end

  let(:drive_time_data_648A4_floats) do
    bands = drive_time_data_648A4
    bands.first['attributes']['Name'] = '648A4 : 0 - 1.21234567'
    bands.first['attributes']['FromBreak'] = 0
    bands.first['attributes']['ToBreak'] = 1.21234567
    bands
  end

  let(:drive_time_data_402) do
    fixture_file_name = "#{::Rails.root}/spec/fixtures/pssg/drive_time_data_402.json"
    File.open(fixture_file_name, 'rb') do |f|
      JSON.parse(f.read)
    end
  end

  let(:pssg_client_stub) { instance_double('Facilities::DrivetimeBands::Client') }

  before do
    allow(Facilities::DrivetimeBands::Client).to receive(:new, &method(:pssg_client_stub))
    allow(pssg_client_stub).to receive(:get_drivetime_bands).and_return([])
  end

  describe 'matching facility' do
    before do
      create :vha_648A4
    end

    it 'populates facility with drive time data overriding existing band' do
      existing_drive_time = create :sixty_mins_648A4

      allow(pssg_client_stub).to receive(:get_drivetime_bands).with(0, 30).and_return(drive_time_data_648A4)
      subject.perform
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands).not_to be_nil
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands.size).to be(1)
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands[0].name).to eql('648A4 : 0 - 10')
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands[0].unit).to eql('minutes')
      expect(DrivetimeBand.find_by(vha_facility_id: '648A4').name).to eql('648A4 : 0 - 10')
      # updates are currently turned off once they are working this should be `.not_to eql`
      expect(DrivetimeBand.find_by(vha_facility_id: '648A4').polygon.to_s).to eql(existing_drive_time.polygon.to_s)
    end

    it 'populates facility with drive time data' do
      allow(pssg_client_stub).to receive(:get_drivetime_bands).with(0, 30).and_return(drive_time_data_648A4)
      subject.perform
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands).not_to be_nil
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands.size).to be(1)
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands[0].name).to eql('648A4 : 0 - 10')
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands[0].unit).to eql('minutes')
      expect(DrivetimeBand.find_by(vha_facility_id: '648A4').name).to eql('648A4 : 0 - 10')
    end

    it 'rounds bands with float bounds' do
      allow(pssg_client_stub).to receive(:get_drivetime_bands).with(0, 30).and_return(drive_time_data_648A4_floats)
      subject.perform
      bands = BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands
      expect(bands).not_to be_nil
      expect(bands.size).to be(1)
      expect(bands[0].min).to eq(0)
      expect(bands[0].max).to eq(10)
      expect(bands[0].name).to eql('648A4 : 0 - 1.21234567')
      expect(bands[0].unit).to eql('minutes')
      expect(DrivetimeBand.find_by(vha_facility_id: '648A4').name).to eql('648A4 : 0 - 1.21234567')
    end

    it 'does not populate facility with drive time data when there are no rings' do
      allow(pssg_client_stub).to receive(:get_drivetime_bands).with(0, 30).and_return(drive_time_data_648A4_no_rings)

      subject.perform

      expect(DrivetimeBand.find_by(name: '648A4 : 0 - 10')).to be_nil
    end

    it 'leaves facility with original drive time band' do
      existing_drive_time = create :sixty_mins_648A4

      allow(pssg_client_stub).to receive(:get_drivetime_bands).with(0, 30).and_return(drive_time_data_402)
      subject.perform
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands).not_to be_nil
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands.size).to be(1)
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands[0].name).to eql('648A4 : 0 - 10')
      expect(BaseFacility.find_facility_by_id('vha_648A4').drivetime_bands[0].unit).to eql('minutes')
      expect(DrivetimeBand.find_by(vha_facility_id: '648A4').polygon.to_s).to eql(existing_drive_time.polygon.to_s)
    end
  end

  describe 'no matching facility' do
    it 'has no drive time data in the database' do
      allow(pssg_client_stub).to receive(:get_drivetime_bands).with(0, 30).and_return(drive_time_data_648A4)
      subject.perform
      expect(BaseFacility.find_facility_by_id('vha_648A4')).to be_nil
      expect(DrivetimeBand.find_by(name: '648A4 : 0 - 10')).to be_nil
    end
  end

  context 'when encountering an error' do
    before do
      Settings.sentry.dsn = 'asdf'
      create :vha_648A4
    end

    after do
      Settings.sentry.dsn = nil
    end

    it 'logs pssg download error to sentry' do
      allow(pssg_client_stub).to receive(:get_drivetime_bands).with(0, 30).and_return(drive_time_data_648A4)
      allow_any_instance_of(
        Facilities::PSSGDownload
      ).to receive(:extract_polygon).with(any_args).and_raise(RGeo::Error::InvalidGeometry)

      expect(Raven).to receive(:capture_exception).with(RGeo::Error::InvalidGeometry, level: 'error')
      expect(Raven).to receive(:extra_context).with('Band name' => drive_time_data_648A4[0]['attributes']['Name'])

      subject.perform
    end
  end
end
