require "logger"
require "Octokit"
require "time"
require "text-table"

#
# Extend Text::Table with markdown support.
# Taken from https://github.com/aptinio/text-table/pull/10
#
class Text::Table
  def to_markdown
    b = @boundary_intersection
    @boundary_intersection = '|'
    rendered_rows = [separator] + text_table_rows.map(&:to_s)
    rendered_rows.unshift [text_table_head.to_s] if head
    @boundary_intersection = b
    rendered_rows.join.gsub('|--', '| :').gsub('--|', ': |')
  end
end

#
# Extend Enumberable classes with a to_markdown_table method
#
module Enumerable
  def to_markdown_table(options = {})
    table = Text::Table.new :rows => self.to_a.dup
    table.head = table.rows.shift
    table.to_markdown
  end
end

class GitHubIssueStats
  VERSION = "0.2.0"

  attr_accessor :client,          # Octokit client for acesing the API
                :logger,          # Logger for writing debugging info
                :sleep_period     # Sleep period between Search API requests

  def initialize(token, verbose=false)
    @logger = Logger.new(STDERR)
    @logger.sev_threshold = verbose ? Logger::DEBUG : Logger::WARN

    @logger.debug "Creating new GitHubIssueStats instance."

    @logger.debug "Creating a new Octokit client with token #{token[0..5]}"

    begin
      @client = Octokit::Client.new(
        :access_token => token,
        :auto_paginate => true,
        :user_agent => "GitHubIssueStats/#{VERSION} (@izuzak) #{Octokit.user_agent}"
      )

      @client.rate_limit
    rescue Octokit::Unauthorized => exception
      @logger.error "Token #{token[0..5]} is not valid"
      raise ArgumentError.new("Token #{token[0..5]} is not valid")
    end

    @logger.debug "Token #{token[0..5]} is valid"
  end

  #
  # Collect and return statistics
  #
  # Input:
  #
  # options = {
  #   :interval_length => "1w",             # 1 week interval
  #   :interval_count => 2,                 # 2 intervals to collect data for
  #   :scopes => ["atom", "atom/atom"],     # atom user and atom/atom repo
  #   :labels => ["issues", "pulls", "bug"] # issues, pulls, and bug label
  # }
  #
  # Output:
  #
  # [
  #   {                                     # each interval will be represented as hash
  #     :interval_end_timestamp => Time,    # end of interval
  #     :interval_start_timestamp => Time,  # beginning of interval
  #     "atom" => {                         # each scope will have a key and hash value
  #        "issues" => {                    # each label will have a key and hash value
  #          :interval_end_total => 1,      # number of items at end of period
  #          :interval_beginning_total => 2,# number of items at beginning of period
  #          :interval_new_total => 3,        # number of new items during period
  #          :interval_closed_total => 4      # number of closed items during period
  #        }
  #      }
  #   }
  # ]
  #
  def get_statistics(options)
    # number_of_calls = get_required_number_of_api_calls(options)
    # @sleep_period = get_api_calls_sleep(number_of_calls)

    stats = []
    for i in 1..options[:interval_count]
      stats << get_stats_for_interval(stats[-1], options)
    end

    return stats
  end

  #
  # Collects statistics for a single interval
  #
  def get_stats_for_interval(previous_slice, options)
    slice = {}

    # set timestamps

    if previous_slice.nil? # initial
      slice[:current_timestamp] = Time.now.utc
      slice[:previous_timestamp] = get_beginning_of_current_period(slice[:current_timestamp], options[:interval_length])
    else # not initial
      slice[:current_timestamp] = previous_slice[:previous_timestamp]
      slice[:previous_timestamp] = compute_previous_time(slice[:current_timestamp], options[:interval_length])
    end

    for scope in options[:scopes]
      scope_stats = {}
      slice[scope] = scope_stats

      for label in options[:labels]
        label_stats = {}
        scope_stats[label] = label_stats

        # current state

        search_options = {
          :scope => scope,
          :label => label,
          :state => "open"
        }

        if previous_slice.nil?
          query_string = get_search_query_string(search_options)
          label_stats[:interval_end_total_url] = get_search_url(query_string)
          label_stats[:interval_end_total] = get_search_total_results(query_string)
        else
          label_stats[:interval_end_total] = previous_slice[scope][label][:interval_beginning_total]
        end

        # number of new issues in period

        search_options = {
          :scope => scope,
          :label => label,
          :created_at => {
            :from => slice[:previous_timestamp],
            :until => slice[:current_timestamp]
          }
        }

        query_string = get_search_query_string(search_options)
        label_stats[:interval_new_total_url] = get_search_url(query_string)
        label_stats[:interval_new_total] = get_search_total_results(query_string)

        # number of closed issues in period

        search_options = {
          :scope => scope,
          :label => label,
          :state => "closed",
          :closed_at => {
            :from => slice[:previous_timestamp],
            :until => slice[:current_timestamp]
          }
        }

        query_string = get_search_query_string(search_options)
        label_stats[:interval_closed_total_url] = get_search_url(query_string)
        label_stats[:interval_closed_total] = get_search_total_results(query_string)

        # number of issues in previous period

        label_stats[:interval_beginning_total] = label_stats[:interval_end_total] + label_stats[:interval_closed_total] - label_stats[:interval_new_total]

        @logger.debug "Computed total at beginning of interval: #{label_stats[:interval_beginning_total]}"
      end
    end

    return slice
  end

  #
  # Call Search API for a query and return total number of results
  #
  def get_search_total_results(query_string)
    sleep_before_api_call()

    @logger.debug "Getting search results for query: #{query_string}"

    # Print something just so the user know something is going on
    if @logger.sev_threshold != Logger::DEBUG
      STDERR.print(".")
      STDERR.flush
    end

    result = @client.search_issues(query_string)
    @logger.debug "Total count: #{result.total_count}"

    if result.incomplete_results
      @logger.error "Incomplete search API results for query #{query_string}"
    end

    return result.total_count
  end

  #
  # Returns the timestamps for the beginning of the current period
  #
  def get_beginning_of_current_period(current_time, period)
    period_type = period[1]

    if period_type == "h"
      return Time.new(current_time.year, current_time.month, current_time.day, current_time.hour, 0, 0, "+00:00")
    elsif period_type == "d"
      return Time.new(current_time.year, current_time.month, current_time.day, 0, 0, 0, "+00:00")
    elsif period_type == "w"
      current_date = Date.new(current_time.year, current_time.month, current_time.day)
      previous_date = current_date - (current_date.cwday - 1)
      previous_time = Time.new(previous_date.year, previous_date.month, previous_date.day, 0, 0, 0, "+00:00")
    elsif period_type == "m"
      return Time.new(current_time.year, current_time.month, 1, 0, 0, 0, "+00:00")
    elsif period_type == "y"
      return Time.new(current_time.year, 1, 1, 0, 0, 0, "+00:00")
    else
      # TODO throw error
    end
  end

  #
  # Computes the the beginning of the period based on the end of a period
  #
  def compute_previous_time(current_time, period)
    period_number, period_type = period.chars
    period_number = Integer(period_number)

    if period_type == "h"
      return current_time - period_number * 3600
    elsif period_type == "d"
      return current_time - period_number * 3600 * 24
    elsif period_type == "w"
      return current_time - 7 * 3600 * 24
    elsif period_type == "m"
      current_date = Date.new(current_time.year, current_time.month, current_time.day)
      previous_date = current_date.prev_month
      previous_time = Time.new(previous_date.year, previous_date.month, previous_date.day, current_time.hour, current_time.min, current_time.sec, "+00:00")
    elsif period_type == "y"
      return Time.new(current_time.year - 1, current_time.month, current_time.day, current_time.hour, current_time.min, current_time.sec, "+00:00")
    else
      # TODO throw error
    end
  end

  #
  # Computes the number of search API calls to collect all the data
  #
  def get_required_number_of_api_calls(options)
    return options[:scopes].size * options[:labels].size * (2 * options[:interval_count] + 1)
  end

  #
  # Computes the required sleep period to avoid hitting the API rate limits
  #
  def sleep_before_api_call()
    @logger.debug "Calculating sleep period for next search API call"

    rate_limit_data = @client.get("https://api.github.com/rate_limit")

    if rate_limit_data[:resources][:core][:remaining] == 0
      reset_timestamp = rate_limit_data[:resources][:core][:reset]
      sleep_seconds = reset_timestamp - Time.now.to_i
      @logger.warn "Remaining regular API rate limit is 0, sleeping for #{sleep_seconds} seconds."
      sleep(sleep_seconds)
    elsif rate_limit_data[:resources][:search][:remaining] == 0
      reset_timestamp = rate_limit_data[:resources][:search][:reset]
      sleep_seconds = reset_timestamp - Time.now.to_i
      @logger.warn "Remaining search API rate limit is 0, sleeping for #{sleep_seconds} seconds."
      sleep(sleep_seconds)
    elsif
      sleep(1)
    end
  end

  #
  # Construct the search query string based on different options.
  #
  def get_search_query_string(options)
    query = ""

    if options[:scope].include?("/")
      query += "repo:#{options[:scope]} "
    else
      query += "user:#{options[:scope]} "
    end

    if options[:label] == "issues"
      query += "is:issue "
    elsif options[:label] == "pulls"
      query += "is:pr "
    else
      query += "label:#{options[:label]} "
    end

    if !options[:state].nil?
      query += "is:#{options[:state]} "
    end

    if !options[:created_at].nil?
      query += "created:#{options[:created_at][:from].iso8601()}..#{options[:created_at][:until].iso8601()} "
    end

    if !options[:closed_at].nil?
      query += "closed:#{options[:closed_at][:from].iso8601()}..#{options[:closed_at][:until].iso8601()} "
    end

    return query.strip
  end

  #
  # Returns the github.com URL for viewing the list of issues which match the
  # given query string
  #
  def get_search_url(query_string)
    return "https://github.com/issues?q=#{query_string}"
  end

  #
  # Generates tables for collected statistics, for easy copy-pasting
  #
  def generate_tables(stats, options)
    def get_headers(labels, scope, output_format)
      if output_format == "markdown"
        return labels.map do |label|
          query_string = get_search_query_string({:scope => scope, :label => label, :state => "open"})
          "[#{label}](#{get_search_url(query_string)})"
        end
      else
        return labels
      end
    end

    def get_period_humanized_name(slice, period_type, index)
      names = {
        "h" => ["Now", "1 hour ago", "hours"],
        "d" => ["Today", "Yesterday", "days"],
        "w" => ["This week", "Last week", "weeks"],
        "m" => ["This month", "Last month", "months"],
        "y" => ["This year", "Last year", "years"]
      }

      if index < 2
        return names[period_type][index]
      else
        return "#{index} #{names[period_type][2]} ago"
      end
    end

    def get_period_date(slice, period_type)
      if period_type == "h"
        return slice[:previous_timestamp].strftime "%Y-%m-%d %H:00"
      elsif period_type == "d"
        return slice[:previous_timestamp].strftime "%Y-%m-%d"
      elsif period_type == "w"
        return slice[:previous_timestamp].strftime "%Y-%m-%d"
      elsif period_type == "m"
        return slice[:previous_timestamp].strftime "%Y-%m"
      elsif period_type == "y"
        return slice[:previous_timestamp].strftime "%Y"
      else
        # TODO throw error
      end
    end

    def get_period_name(slice, interval, index, type)
      period_number, period_type = interval.chars
      if type == "markdown"
        return "**#{get_period_humanized_name(slice, period_type, index)}** <br>(#{get_period_date(slice, period_type)})"
      else
        return "#{get_period_humanized_name(slice, period_type, index)} (#{get_period_date(slice, period_type)})"
      end
    end

    def get_period_stats(slice, labels, scope, type)
      def get_difference_string(stats)
        difference_string = "+#{stats[:interval_new_total]}, -#{stats[:interval_closed_total]}"

        # TODO: maybe something like this in the future
        # difference = stats[:interval_new_total] - stats[:interval_closed_total]
        # difference_string = "#{difference}, +#{stats[:interval_new_total]}, -#{stats[:interval_closed_total]}"
        #
        # return "▲" + difference_string if difference > 0
        # return "▼" + difference_string if difference < 0
        # return "▶" + difference_string
      end

      if type == "markdown"
        return labels.map do |label|
          "**#{slice[scope][label][:interval_end_total]}** <br>(#{get_difference_string(slice[scope][label])})"
        end
      else
        return labels.map do |label|
          "#{slice[scope][label][:interval_end_total]} (#{get_difference_string(slice[scope][label])})"
        end
      end
    end

    tables = {}

    for scope in options[:scopes]
      data = []

      data << ["period"] + get_headers(options[:labels], scope, options[:output_format])
      stats.each_with_index do |slice, index|
        data << [get_period_name(slice, options[:interval_length], index, options[:output_format])] + get_period_stats(slice, options[:labels], scope, options[:output_format])
      end

      tables[scope] = options[:output_format] == "markdown" ? data.to_markdown_table : data.to_table(:first_row_is_head => true).to_s
    end

    return tables
  end
end
