module Scrb
  class Iteration
    module NextAware
      # make an iteration aware of rules about how to build the next one

      def build_next
        self.class.new(
          name: next_name,
          start_date: next_start_date,
          end_date: next_end_date,
          group_ids: group_ids
        )
      end

      def next_start_date
        (end_date + 1.day).to_date
      end

      def length
        (end_date - start_date).to_i
      end

      def next_end_date
        candidate = next_start_date.next_occurring(:saturday).next_occurring(:saturday).to_date
        days_left = (candidate.end_of_month - candidate).to_i

        if days_left < 12
          puts "WARNING: #{candidate} is too close to the end of the month. Moving to the following Saturday."
          candidate = (candidate + 1.day).next_occurring(:saturday).to_date
        end

        candidate
      end

      def next_name
        month_str, half_str, year_str = name.split(" ")

        [
          (half_str == "H1") ? month_str : (start_date + 1.month).strftime("%B"),
          (half_str == "H1") ? "H2" : "H1",
          (month_str == "December" && half_str == "H2") ? (year_str.to_i + 1).to_s : year_str
        ].join(" ")
      end
    end

    include NextAware
    include ActiveModel::Model

    attr_reader :created_at, :start_date, :end_date
    attr_accessor :app_url, :associated_groups, :description, :entity_type, :follower_ids, :global_id,
      :group_ids, :group_mention_ids, :id, :label_ids, :labels, :member_mention_ids, :mention_ids,
      :name, :stats, :status, :updated_at

    [:started, :done, :unstarted].each { |status| define_method("#{status}?") { self.status.to_sym == status } }
    alias_method :current?, :started?
    alias_method :finished?, :done?

    # class methods ##########################################

    class << self
      def where(attrs)
        all
          .select { |i| attrs[:name].nil? || i.name.match(/#{attrs[:name]}/i) }
          .select { |i| attrs[:status].nil? || i.status.match(/#{attrs[:status]}/i) }
      end

      def all
        ::Scrb.shortcut.iterations.list[:content].map { |h| Iteration.new(h) }
      end

      def find_current
        all.find(&:current?)
      end

      def find_futuremost
        where(status: :unstarted).max_by(&:start_date)
      end

      def find_previous
        all.select(&:finished?).max_by(&:end_date)
      end

      def find_unstarted_by_name(name)
        all.select(&:unstarted?).find { |i| i.name.match(/#{name}/i) }
      end
    end

    # instance methods #########################################

    def exists?
      self.class.where(name: name).any?
    end

    def save
      return true if exists?

      post_attrs = %i[name start_date end_date].each_with_object({}) { |k, o| o[k] = send(k) }.to_json

      result = ScrbClient.post("/iterations", body: post_attrs)

      Iteration.new(result)
    end

    def stories
      @stories ||= ::Scrb.shortcut.iterations(id).stories.list[:content].map { |s| Story.new(s) }
    end

    def created_at=(datestr)
      @created_at = Date.parse(datestr.to_s)
    end

    def start_date=(datestr)
      @start_date = Date.parse(datestr.to_s)
    end

    def end_date=(datestr)
      @end_date = Date.parse(datestr.to_s)
    end
  end
end
