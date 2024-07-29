# frozen_string_literal: true
class ProposalVoteFormBuilder < ActionView::Helpers::FormBuilder
  def vote_button(vote_type, voted, voted_yes, voted_no)
    yes_vote = (vote_type == :yes)

    if !voted
      label = yes_vote ? "Vote Yes" : "Vote No"
    elsif (yes_vote && voted_no) || (!yes_vote && voted_yes)
      label = "Change vote to #{yes_vote ? 'Yes' : 'No'}"
    else
      return nil  # Don't show button if already voted
    end

    @template.submit_tag(label)
  end
end