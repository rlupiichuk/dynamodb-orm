require 'spec_helper'

RSpec.describe Mes::Dynamo::Model do
  include_context 'with dynamodb table',
    :movies,
    attribute_definitions: [{
      attribute_name: 'content_id',
      attribute_type: 'S'
    }],
    key_schema: [{
      attribute_name: 'content_id',
      key_type: 'HASH'
    }]

  class Movie
    include Mes::Dynamo::Model
    field :title
  end

  let(:content_id) { 'v-global' }
  let(:title)      { 'The Secret Life of Walter Mitty' }
  let(:movie)      { Movie.new }

  describe '#primary_key' do
    class TableWithCustomPrimaryKey
      include Mes::Dynamo::Model
      table primary_key: 'custom_id'
    end

    it 'saves primary_key' do
      expect(TableWithCustomPrimaryKey.primary_key).to eq('custom_id')
    end
  end

  describe '#attributes' do
    it 'returns empty hash' do
      expect(movie.attributes).to eq({})
    end

    it 'returns updated attributes' do
      movie.title = title
      expect(movie.attributes).to eq({ 'title' => title })
    end
  end

  describe '#read_attribute' do
    before do
      movie.attributes.merge!('title' => title)
    end

    it 'reads attribute' do
      expect(movie.read_attribute(:title)).to eq(title)
    end
  end

  describe '#write_attribute' do
    context 'when attribute is defined' do
      it 'writes an attribute' do
        movie.write_attribute(:title, title)
        expect(movie.title).to eq(title)
      end
    end

    context 'when attribute is not defined' do
      it 'does nothing' do
        movie.write_attribute(:does_not_exists, title)
        expect(movie.attributes).to eq({})
      end
    end
  end

  describe '#save!' do
    context 'when can be saved' do
      before do
        movie.attributes.merge!(
          'content_id' => content_id,
          'title' => title
        )
      end

      it 'saves new object' do
        expect {
          movie.save!
        }.to change { Movie.count }.by(1)
      end
    end

    context 'when cannot be saved' do
      it 'raises exception' do
        expect {
          movie.save!
        }.to raise_error Mes::Dynamo::GenericError
      end
    end
  end

  describe '#save' do
    context 'when can be saved' do
      before do
        movie.attributes.merge!(
          'content_id' => content_id,
          'title' => title
        )
      end

      it 'returns true' do
        expect(movie.save).to eq true
      end
    end

    context 'when cannot be saved' do
      it 'returns false' do
        expect(movie.save).to eq false
      end
    end
  end

  describe '#assign_attributes' do
    let(:attributes) { { 'content_id' => content_id, 'title' => title } }

    it 'saves new object' do
      movie.assign_attributes(attributes)
      expect(movie.attributes).to eq(attributes)
    end
  end

  describe '#update_attributes' do
    let(:attributes) { { 'content_id' => content_id, 'title' => title } }

    it 'saves new object' do
      movie.update_attributes(attributes)
      expect(Movie.find(content_id).attributes).to eq(attributes)
    end
  end

  describe '#delete' do
    let(:movie) do
      Movie.create!(
        content_id: 'v-delete',
        title: title
      )
    end

    it 'deletes items' do
      movie.delete
      expect(Movie.count).to eq 0
    end
  end

  describe '.table_name' do
    context 'when is not assigned' do
      it { expect(Movie.table_name).to eq('movies') }
    end

    context 'when is assigned' do
      class FunnyMovie
        include Mes::Dynamo::Model
        table name: 'custom_table_name'
      end

      it { expect(FunnyMovie.table_name).to eq('custom_table_name') }
    end
  end

  describe '.create!' do
    it 'creates record' do
      expect {
        Movie.create!(
          content_id: 'v-create!',
          title: title
        )
      }.to change { Movie.count }.by(1)
    end
  end

  describe '.find!' do
    context 'when document exists' do
      before do
        Movie.create!(
          content_id: content_id,
          title: title
        )
      end

      it 'feches document by id' do
        result = Movie.find!(content_id)
        expect(result.title).to eq(title)
      end
    end

    context 'when document does not exist' do
      it 'throws exception' do
        expect {
          Movie.find!('no-such-record')
        }.to raise_error(Mes::Dynamo::RecordNotFound)
      end
    end
  end

  describe '.count' do
    context 'when table does not exist' do
      class ModelWithNoTable
        include Mes::Dynamo::Model
      end

      it 'raise exception' do
        expect {
          ModelWithNoTable.count
        }.to raise_error(Mes::Dynamo::TableDoesNotExist)
      end
    end
  end

  describe '.truncate!' do
    before do
      Movie.create!(
        content_id: content_id,
        title: title
      )
    end

    it 'truncates tables' do
      Movie.truncate!
      expect(Movie.count).to eq(0)
    end
  end
end