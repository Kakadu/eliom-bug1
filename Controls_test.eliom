open Eliom_content.Html5.D
open Printf

module App = Eliom_registration.App (
  struct
    let application_name = "client"
  end)

let post_wizard = Eliom_service.service ~path:[] ~get_params:Eliom_parameter.unit ()

{shared{
  open Eliom_content.Html5.D
  external (|>): 'a -> ('a -> 'b) -> 'b = "%revapply"
}}

{server{
  type rpc_res_t = (int32 * string * int64) deriving (Json)
  let template (maxexp,descr,_) =
    div ~a:[a_class ["suggestion-item"]]
      [ span ~a:[a_class ["post_tag"]]
          [ span ~a:[a_class ["match"]] [pcdata descr]
          ]
      ; br ()
      ; span ~a:[a_style "item-multiplier"] [pcdata (sprintf "≤ %s" (Int32.to_string maxexp))]
      ] |> Lwt.return


  let suggestions query: rpc_res_t list Lwt.t =
    Lwt.return [(32l,"description",Int64.one);(64l, "description2", Int64.zero)]

  let rpc_make_suggestions
      : (string, rpc_res_t list)
      Eliom_pervasives.server_function =
    server_function Json.t<string> suggestions

  let template_rpc
      : (rpc_res_t, [ Html5_types.div ] Eliom_content.Html5.D.elt)
      Eliom_pervasives.server_function
      = server_function Json.t<rpc_res_t> template
}}

let wizard2_handler () _ =
  Eliom_tools.D.html ~title:"title" (body [ p  [pcdata "do changes here"] ]) |> Lwt.return

let wizard1_handler () () =
  let wizard2_service = App.register_post_coservice
    ~scope:Eliom_common.default_session_scope
    ~fallback:post_wizard
    ~post_params:(Eliom_parameter.string "name")
    wizard2_handler in

  let container = div [] in

  Eliom_tools.D.html ~title:"title"
   (body
      [ h2 [pcdata "You will see some error in firebug console"]
      ; post_form wizard2_service
        (fun (area_name) ->
          [ div
              [ Controls.text_with_suggestions
                  ~container
                  ~name:area_name
                  ~attribs:[]
                  rpc_make_suggestions
                  template_rpc
              ; container
              ]
          ]
        ) ()
      ]
  ) |> Lwt.return

let () =
    App.register ~service:post_wizard wizard1_handler
