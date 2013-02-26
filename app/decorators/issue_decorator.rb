class IssueDecorator < Draper::Decorator
  delegate :votes,
           :title,
           :to_json,
           :description,
           :vote_connections,
           :accountability,
           :published?,
           :cache_key,

           # move to decorator?
           :status_text,
           :editor_name,
           :last_updated_by_name,
           :stats,
           :downcased_title

  def explanation
    h.t('app.issues.explanation', count: votes.size, url: h.votes_issue_path(model)).html_safe
  end

  def published_at
    h.l model.published_at.localtime, format: :text
  end

  def updated_at
    h.l model.updated_at.localtime, format: :text
  end

  def time_since_updated
    h.distance_of_time_in_words_to_now model.updated_at.localtime
  end

  def position_groups
    grouped = Party.order(:name).group_by do |p|
      model.stats.key_for(model.stats.score_for(p))
    end

    [:against, :for_and_against, :for].map do |key|
      label = OpenStruct.new(:icon => "taxonomy-icons/issue_#{key}.png", :text => h.t("app.#{key}"))

      parties = grouped[key] || []
      [label, parties]
    end
  end

  def promises_by_party
    # {
    #   'A'    => { 'Partiprogram' => promises, 'Regjeringserklæring' => promises },
    #   'FrP'  => { 'Partiprogram' => promises },
    # }

    @promises_by_party ||= (
      result = {}

      model.promises.includes(:parties).each do |promise|
        promise.parties.each do |party|
          data = result[party] ||= {}
          (data[promise.source.downcase] ||= []) << promise
        end
      end

      result
    )
  end

  def party_groups
    government = Party.in_government.to_a
    opposition = Party.order(:name).to_a - government

    gov = IssuePartyDecorator.decorate_collection government, context: self
    opp = IssuePartyDecorator.decorate_collection opposition, context: self

    groups = []

    if government.any?
      groups << PartyGroup.new(h.t('app.parties.group.governing'), gov)
      groups << PartyGroup.new(h.t('app.parties.group.opposition'), opp)
    else
      # if no-one's in government, we only need a single group with no name.
      groups << PartyGroup.new('', opp)
    end

    groups
  end

  class PartyGroup < Struct.new(:name, :parties)
  end

  class IssuePartyDecorator < Draper::Decorator
    alias_method :issue, :context
    delegate :external_id, :image_with_fallback, :name

    def link(opts = {}, &blk)
      h.link_to h.party_path(model), opts, &blk
    end

    def logo(opts = {})
      size = opts.delete(:size) || '96x96'
      h.image_tag model.image_with_fallback.thumb(size).url, opts.merge(alt: "#{model.name}s logo")
    end

    def position_logo
      key = issue.stats.key_for(score) # FIXME: take the party, not the score

      if key.nil? || key == :not_participated
        # could add taxonomy-icons/issue_not_participated.png
      else
        h.image_tag "taxonomy-icons/issue_#{key}.png"
      end
    end

    def promise_logo
      key = issue.accountability.key_for(model)
      h.image_tag "taxonomy-icons/promise_#{key}.png"
    end

    def has_promises?
      promise_groups && promise_groups.values.any?
    end

    def promise_groups
      @promise_groups ||= issue.promises_by_party[model]
    end

    def score
      issue.stats.score_for(model)
    end

    def position_text
      [
        issue.stats.text_for(model, html: true),
        h.t('app.lang.infinitive_particle'),
        issue.downcased_title
      ].join(' ').html_safe
    end

    def accountability_text
      issue.accountability.text_for(model)
    end

    def votes
      votes = issue.vote_connections.map { |vc| PartyVote.new(model, vc) }
      votes.select { |e| e.participated? }
    end
  end

  class PartyVote < Struct.new(:party, :vote_connection)
    def participated?
      stats.party_participated? party
    end

    def direction
      @direction ||= stats.party_for?(party) ? 'for' : 'against'
    end

    def title
      vote_connection.title
    end

    def label
      direction == 'for' ? 'For' : 'Mot'
    end

    def stats
      @stats ||= vote_connection.vote.stats
    end
  end
end