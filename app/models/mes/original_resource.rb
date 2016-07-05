module Mes
  class OriginalResource < ::Mes::Dynamo::Model
    include ::Mes::Dynamo::Timestamps

    table name: "lte-original-resources-#{RACK_ENV}",
          primary_key: :uuid

    field :content_id, type: :string
    field :period,     type: :number
    field :data, default: -> { {} }

    table_index :period, range: :created_at, name: 'period_created_at_index'

    before_create do
      self.uuid ||= SecureRandom.uuid
    end

    before_save do
      self.period = ::Mes::PeriodHelper.from_unix_timestamp(created_at || Time.now)
    end

    validates :uuid,       presence: true
    validates :content_id, presence: true
    validates :period,     presence: true

    def asset_type
      data['asset_type']
    end
  end
end
