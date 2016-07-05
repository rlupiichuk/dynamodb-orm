require 'spec_helper'

RSpec.describe Mes::AccessToken do
  context 'attributes' do
    describe 'default values' do
      {
        active: true,
        type: 'EMBED',
        device_class: 'BROWSER'
      }.each do |attr, value|
        it "sets default value for #{attr}" do
          expect(subject.send(attr)).to eq(value)
        end
      end
    end

    describe '#access_token' do
      subject { described_class.new }

      it 'is generated automaticaly' do
        expect { subject.save }
          .to change { subject.access_token }
          .from(nil)
      end

      it 'is not replacing the manualy set token' do
        subject.access_token = 'some_token'
        expect { subject.save }.not_to change { subject.access_token }
      end

      it 'is generates 32-char string' do
        subject.save
        expect(subject.access_token.size).to eq 32
      end
    end
  end

  describe '.by_tenant_id' do
    include_context 'with mes tables'

    before do
      FactoryGirl.create(:access_token, tenant_id: 'u1')
      FactoryGirl.create(:access_token, tenant_id: 'u1')
      FactoryGirl.create(:access_token, tenant_id: 'u1', active: false)
      FactoryGirl.create(:access_token, tenant_id: 'u2')
    end

    it 'filters tokens by tenant_id' do
      expect(
        described_class.by_tenant_id('u1').to_a.size
      ).to eq(2)
    end
  end

  describe '#assign_id_token!' do
    let(:access_token) { 'x-777' }
    let(:content_id_service_client) { double('Mes::ContentIdServiceClient') }

    before do
      allow(Mes::ContentIdServiceClient).to receive(:new)
        .and_return(content_id_service_client)
      allow(content_id_service_client).to receive(:next_access_token_id)
        .and_return(access_token)
    end

    it 'assigns a token generated by client' do
      subject.assign_id_token!
      expect(subject.id_token).to eq(access_token)
    end
  end
end
