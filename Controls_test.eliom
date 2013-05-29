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
  type rpc_res_t = (string) deriving (Json)
  let template descr = div [ span [ span  [pcdata descr] ] ] |> Lwt.return

  let suggestions query: rpc_res_t list Lwt.t =
    Lwt.return [("dummy text"); ("dummy text 2")]

  (* this RPC will be passes to text_with_suggestions and will generate data *)
  let rpc_make_suggestions
      : (string, rpc_res_t list)
      Eliom_pervasives.server_function =
    server_function Json.t<string> suggestions

  (* this RPC will make divs from data gotten by previous RPC *)
  let template_rpc
      : (rpc_res_t, [ Html5_types.div ] Eliom_content.Html5.D.elt)
      Eliom_pervasives.server_function
      = server_function Json.t<rpc_res_t> template
}}

let wizard2_handler () () =
  Eliom_tools.D.html ~title:"title" (body [ p  [pcdata "do changes here"] ]) |> Lwt.return

let wizard1_handler () () =
  let wizard2_service = App.register_post_coservice
    ~scope:Eliom_common.default_session_scope
    ~fallback:post_wizard
    ~post_params:(Eliom_parameter.unit)
    wizard2_handler in

  let container = div ~a:[a_id "my_container"] [] in

  let () = Controls.text_with_suggestions ~container rpc_make_suggestions template_rpc in

  Eliom_tools.D.html ~title:"title"
   (body
      [ h2 [pcdata "You will see some error in firebug console"]
      ; post_form wizard2_service (fun () -> [ container ]) ()
      ]
  ) |> Lwt.return

let () = App.register ~service:post_wizard wizard1_handler
