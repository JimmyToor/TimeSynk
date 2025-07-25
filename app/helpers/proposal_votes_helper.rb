module ProposalVotesHelper
  def format_vote(vote)
    case vote
    when true
      "Yes"
    when false
      "No"
    else
      "Undecided"
    end
  end

  def vote_icon(vote)
    if vote.yes_vote.nil?
      "undecided.svg"
    else
      vote.yes_vote ? "checkmark.svg" : "xmark.svg"
    end
  end
end
