# encoding: UTF-8

module Hdo
  module Stats
    class VoteScorer

      #
      # Return CSV for comparing the effect of weights in all published issues
      #

      def self.csv
        require 'csv'

        parties = Party.order(:name)

        CSV.generate do |csv|
          csv << ['Tittel', 'Vektet tekst', 'Vektet %', 'Uvektet tekst', 'Uvektet %', 'Differanse']

          Issue.published.each do |issue|
            weighted   = new(issue)
            unweighted = new(issue, weighted: false)

            parties.each do |party|
              weighted_score   = weighted.score_for(party)
              unweighted_score = unweighted.score_for(party)

              csv << [
                issue.title,
                weighted.text_for(party),
                weighted_score,
                unweighted.text_for(party),
                unweighted_score,
                weighted_score.to_i - unweighted_score.to_i
              ]
            end
          end
        end
      end

      def initialize(model, opts = {})
        @weighted = opts.fetch(:weighted) { true }

        vote_connections = model.vote_connections.includes(vote: {vote_results: {representative: {party_memberships: :party}}})
        @data = compute(vote_connections)
      end

      def score_for(entity)
        @data[entity]
      end

      def text_score_for(entity)
        s = score_for(entity)
        s ? "#{s.to_i}%" : I18n.t('app.uncertain')
      end

      def score_for_group(parties)
        @data[parties] ||= (
          if parties.size.zero?
            nil
          else
            parties.map { |party| @data[party] || 0 }.sum / parties.size
          end
        )
      end

      def as_json(opts = nil)
        res = {}

        @data.each do |key, value|
          name = case key
                 when Array
                   key.map { |e| e.name }.join(',')
                 else
                   key.name
                 end

         res[name] = value
        end

        res
      end

      def text_for(entity, opts = {})
        entity_name = opts[:name] || entity.name
        score = score_for(entity)

        text_for_entity score, entity_name, opts
      end

      def text_for_group(entities, opts = {})
        entity_name = opts.fetch(:name)
        score = score_for_group(entities)

        text_for_entity score, entity_name, opts
      end

      # FIXME: API is inconsistent with AccountabilityScorer - should take a party, not a score
      def key_for(score)
        if score.nil?
          return :not_participated
        end

        # if you change the scoring, remember to change the 'about method' page as well.
        case score
        when 0...33
          :against
        when 33...66
          :for_and_against
        when 66..100
          :for
        end
      end

      private

      def text_for_entity(score, entity_name, opts)
        key = key_for(score) or raise "unknown score: #{score}"
        key = "app.votes.scores.#{key}"
        key << "_html" if opts[:html]

        I18n.t(key, name: entity_name).html_safe
      end

      def compute(connections)
        weight_sums = Hash.new(0)
        sums        = Hash.new(0)

        connections.each do |vote_connection|
          weight = @weighted ? vote_connection.weight : 1

          vote_percentages_for(vote_connection, weight).each do |entity, percent|
            if percent
              weight_sums[entity] += weight
              sums[entity] += percent
            end
          end
        end

        result = {}

        sums.each do |entity, total|
          weight_sum = weight_sums.fetch(entity)

          if weight_sum.zero?
            result[entity] = 0
          else
            result[entity] = (total * 100 / weight_sum).to_i
          end
        end

        result
      end

      private

      def vote_percentages_for(vote_connection, weight)
        vote         = vote_connection.vote
        vote_results = vote.vote_results
        by_party     = vote_results.group_by { |v| v.representative.party_at(vote.time) }
        res          = {}

        meth = vote_connection.matches? ? :for? : :against?

        by_party.each do |party, votes|
          for_count, against_count = 0, 0

          votes.each do |vote_result|
            next if ignore_result?(vote_result, vote_connection)

            if vote_result.__send__(meth)
              res[vote_result.representative] = weight
              for_count += 1
            else
              res[vote_result.representative] = 0
              against_count += 1
            end
          end

          total = (for_count + against_count)

          if total.zero?
            # only absence
            res[party] = nil
          else
            res[party] = (for_count / total.to_f) * weight
          end
        end

        res
      end

      def ignore_result?(vote_result, vote_connection)
        vote_result.absent? ||
          (vote_result.against? && vote_connection.proposition_type == 'alternate_national_budget')
      end

    end
  end
end
