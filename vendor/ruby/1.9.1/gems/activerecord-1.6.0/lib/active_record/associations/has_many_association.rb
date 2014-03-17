module ActiveRecord
  module Associations
    class HasManyAssociation < AssociationCollection #:nodoc:
      def initialize(owner, association_name, association_class_name, association_class_primary_key_name, options)
        super
        @conditions = sanitize_sql(options[:conditions])

        construct_sql
      end

      def build(attributes = {})
        if attributes.is_a?(Array)
          attributes.collect { |attr| create(attr) }
        else
          load_target
          record = @association_class.new(attributes)
          record[@association_class_primary_key_name] = @owner.id unless @owner.new_record?
          @target << record
          record
        end
      end

      def find_all(runtime_conditions = nil, orderings = nil, limit = nil, joins = nil)
        if @options[:finder_sql]
          records = @association_class.find_by_sql(@finder_sql)
        else
          sql = @finder_sql.dup
          sql << " AND #{sanitize_sql(runtime_conditions)}" if runtime_conditions
          orderings ||= @options[:order]
          records = @association_class.find_all(sql, orderings, limit, joins)
        end
      end

      # Count the number of associated records. All arguments are optional.
      def count(runtime_conditions = nil)
        if @options[:finder_sql]
          @association_class.count_by_sql(@finder_sql)
        else
          sql = @finder_sql
          sql << " AND #{sanitize_sql(runtime_conditions)}" if runtime_conditions
          @association_class.count(sql)
        end
      end
      
      # Find the first associated record.  All arguments are optional.
      def find_first(conditions = nil, orderings = nil)
        find_all(conditions, orderings, 1).first
      end

      def find(*args)
        # Return an Array if multiple ids are given.
        expects_array = args.first.kind_of?(Array)

        ids = args.flatten.compact.uniq

        # If no ids given, raise RecordNotFound.
        if ids.empty?
          raise RecordNotFound, "Couldn't find #{@association_class.name} without an ID"

        # If using a custom finder_sql, scan the entire collection.
        elsif @options[:finder_sql]
          if ids.size == 1
            id = ids.first
            record = load_target.detect { |record| id == record.id }
            expects_array? ? [record] : record
          else
            load_target.select { |record| ids.include?(record.id) }
          end

        # Otherwise, delegate to association class with conditions.
        else
          args << { :conditions => "#{@association_class_primary_key_name} = #{@owner.quoted_id} #{@conditions ? " AND " + @conditions : ""}" }
          @association_class.find(*args)
        end
      end

      # Removes all records from this association.  Returns +self+ so
      # method calls may be chained.
      def clear
        @association_class.update_all("#{@association_class_primary_key_name} = NULL", "#{@association_class_primary_key_name} = #{@owner.quoted_id}")
        @target = []
        self
      end

      protected
        def find_target
          find_all
        end

        def count_records
          if has_cached_counter?
            @owner.send(:read_attribute, cached_counter_attribute_name)
          elsif @options[:counter_sql]
            @association_class.count_by_sql(@counter_sql)
          else
            @association_class.count(@counter_sql)
          end
        end

        def has_cached_counter?
          @owner.attribute_present?(cached_counter_attribute_name)
        end

        def cached_counter_attribute_name
          "#{@association_name}_count"
        end

        def insert_record(record)
          record[@association_class_primary_key_name] = @owner.id
          record.save
        end

        def delete_records(records)
          ids = quoted_record_ids(records)
          @association_class.update_all(
            "#{@association_class_primary_key_name} = NULL", 
            "#{@association_class_primary_key_name} = #{@owner.quoted_id} AND #{@association_class.primary_key} IN (#{ids})"
          )
        end

        def target_obsolete?
          false
        end

        def construct_sql
          if @options[:finder_sql]
            @finder_sql = interpolate_sql(@options[:finder_sql])
          else
            @finder_sql = "#{@association_class_primary_key_name} = #{@owner.quoted_id}"
            @finder_sql << " AND #{interpolate_sql(@conditions)}" if @conditions
          end

          if @options[:counter_sql]
            @counter_sql = interpolate_sql(@options[:counter_sql])
          elsif @options[:finder_sql]
            @options[:counter_sql] = @options[:finder_sql].gsub(/SELECT (.*) FROM/i, "SELECT COUNT(*) FROM")
            @counter_sql = interpolate_sql(@options[:counter_sql])
          else
            @counter_sql = "#{@association_class_primary_key_name} = #{@owner.quoted_id}"
            @counter_sql << " AND #{interpolate_sql(@conditions)}" if @conditions
          end
        end
    end
  end
end
