module GameProposalsHelper
  def proposal_vote_form_for(game_proposal, proposal_vote, vote_type, voted, voted_yes, voted_no, &block)
    url = voted ?
            proposal_vote_path(proposal_vote) :
            game_proposal_proposal_votes_path(game_proposal)

    method = voted ? :patch : :post

    form_with(model: proposal_vote, url: url, method: method, builder: ProposalVoteFormBuilder) do |f|
      f.hidden_field(:yes_vote, value: vote_type == :yes) +
        capture { block.call(f) }
    end
  end
end
