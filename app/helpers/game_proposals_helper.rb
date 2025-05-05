module GameProposalsHelper
  def card_link_to_game_proposal(game_proposal)
    link_to game_proposal, class: "bg-primary-400 dark:bg-primary-900 dark:text-accent-500 dark:text-white text-xs
             font-medium px-2 py-0.5 rounded hover:underline -translate-x-2",
      title: "Go to #{game_proposal.game_name} - #{game_proposal.group.name}",
      data: {turbo_frame: "_top"} do
      content_tag(:svg, xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor", class: "h-full size-6") do
        content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", d: "m5.25 4.5 7.5 7.5-7.5 7.5m6-15 7.5 7.5-7.5 7.5")
      end
    end
  end
end
