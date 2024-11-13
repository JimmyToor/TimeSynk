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

end
