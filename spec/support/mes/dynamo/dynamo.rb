module DynamoDBSpecHelpers
  def create_table(table_name, opts)
    check_schema(opts[:attribute_definitions])
    check_schema(opts[:key_schema])

    client.create_table(
      opts.merge(
        table_name: table_name,
        provisioned_throughput: { read_capacity_units: 1, write_capacity_units: 1 }
      )
    )
    wait_till_table_create(table_name)
  end

  def drop_table(table_name)
    client.delete_table(table_name: table_name) if table_exists?(table_name)
  end

  def drop_all_tables
    response = client.list_tables
    response.table_names.each do |table_name|
      drop_table(table_name)
    end
  end

  def describe_table(table_name)
    client.describe_table(table_name: table_name).table.to_h
  end

  def table_exists?(table_name)
    describe_table(table_name)[:table_status] == 'ACTIVE'
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    false
  end

  def wait_till_table_create(table_name)
    100.times do
      break if table_exists?(table_name)
      sleep 0.02
    end
  end

  def truncate_table(table_name, opts)
    primary_key = opts[:key_schema][0][:attribute_name]
    response = client.scan(
      table_name: table_name,
      attributes_to_get: [primary_key],
      select: 'SPECIFIC_ATTRIBUTES'
    )
    response.items.each do |item|
      client.delete_item(
        table_name: table_name,
        key: { primary_key => item[primary_key] }
      )
    end
  end

  private

  def client
    Mes::Dynamo::Connection.connect
  end

  def check_schema(array)
    raise ArgumentError, 'schema should be an array' unless array.is_a?(Array)
    raise ArgumentError, 'all elements should be hashes' if array.any? { |el| !el.is_a?(Hash) }
  end
end

RSpec.configure do |config|
  config.include DynamoDBSpecHelpers
end
