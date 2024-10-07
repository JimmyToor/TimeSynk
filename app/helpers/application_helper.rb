module ApplicationHelper
  def match_request_frame_ids(frame_ids, alternate_frame_id)
    if turbo_frame_request? && frame_ids.include?(turbo_frame_request_id)
      turbo_frame_request_id
    else
      alternate_frame_id
    end
  end

  def modal_wrapper(modal_title, &)
    if turbo_frame_request_id == "modal_frame"
      render partial: "shared/modal", locals: { modal_title: modal_title, modal_body: capture(&) }
    else
      capture(&)
    end
  end

  def open_unless_value(value)
    value ? "data-dialog-open-value=false" : "data-dialog-open-value=true"
  end

end
