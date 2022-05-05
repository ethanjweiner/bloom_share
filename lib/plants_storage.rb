=begin

Wishlist:

- Plants#initialize(logger, user_id)
  - Connect to plant database
  - Setup the logger
  - Store the current `user_id` for use in searches
- Plants#search: Returns all public plants + all plants created by given user

Note: Uses the `Plant` class for plant creation

=end

require 'pg'
require 'csv'
require_relative './plant'
require 'pry'

class NoPlantFoundError < StandardError
  def initialize(msg="No plant found.")
    super(msg)
  end
end

class PlantsStorage
  PAGE_LIMIT = 10

  NUMERICAL_FILTERS = %w(precipitation_minimum
                         precipitation_maximum
                         temperature_minimum)

  def initialize(logger: nil)
    @db = PG.connect(dbname: 'bloomshare') # Configure for production
    @csv_path = 'data/plants.csv'
    @logger = logger
  end

  def query(sql, params)
    @logger.info(sql) if @logger
    @db.exec_params(sql, params)
  end

  # search : Hash of Filters, Integer -> List of Plants
  # Returns a list of `PAGE_LIMIT` plants starting at a given offset
  # Only includes public plants or plants created by the current user
  # rubocop:disable Metrics/MethodLength
  def search(filters, limit: PAGE_LIMIT)
    # Note: Add functionality to include user-specific plants to result
    filters = filters.reject do |_, value|
      !value || value.empty?
    end

    return [] if filters.empty?

    # We must create a string that interpolates all filters
    conditions_string, condition_params = filters_to_conditions(filters)

    sql = <<~SQL
          SELECT * FROM plants
            WHERE #{conditions_string} AND is_public = true
          ORDER BY scientific_name
          LIMIT $1;
          SQL

    result = query(sql, [limit] + condition_params)
    result.map { |tuple| Plant.new(tuple) }
  end
  # rubocop:enable Metrics/MethodLength

  # Retrieves a conditions string & associated parameters for that string
  # Just use a manual approach
  def filters_to_conditions(filters, first_placeholder: 2)
    conditions = []
    condition_params = []
    n = first_placeholder

    filters.each do |filter, value|
      if filter == 'id'
        conditions << "(#{filter} = $#{n})"
        condition_params.push(value.to_i)
        n += 1
      elsif NUMERICAL_FILTERS.include?(filter)
        min, max = value.split(', ')
        conditions << "(#{filter} BETWEEN $#{n} AND $#{n + 1})"
        condition_params.push(min, max)
        n += 2
      elsif value.is_a? Array
        sub_conditions = []
        value.each do |option|
          sub_conditions << "#{filter} ~* $#{n}"
          condition_params.push(option)
          n += 1
        end

        conditions << "(#{sub_conditions.join(' OR ')})"
      else
        conditions << "(#{filter} ~* $#{n})"
        condition_params.push(value)
        n += 1
      end
    end
    
    [conditions.join(' AND '), condition_params]
  end

  # find_by_id : String -> Plant
  # Returns a singular plant with the given `id`
  def find_by_id(id)
    result = search({ "id" => id }, limit: 1)

    if result.empty?
      raise NoPlantFoundError.new, "No plant found with id #{id}."
    end

    result[0]
  end

  def filters_to_conditions_string(filters)
    conditions = filters.map do |key, value|
      filter_to_condition(key, value)
    end

    conditions.join(' AND ')
  end
end