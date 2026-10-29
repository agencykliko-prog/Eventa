-- Les fonctions SECURITY DEFINER ne doivent pas être appelables via /rest/v1/rpc
-- au-delà du nécessaire.

-- Fonctions de déclencheur : jamais appelées directement. Le droit EXECUTE
-- n'est vérifié qu'à la création du déclencheur, pas à son exécution.
revoke execute on function
  public.add_event_owner(),
  public.apply_verification(),
  public.handle_new_user(),
  public.notify_new_message(),
  public.notify_new_quote(),
  public.notify_new_request(),
  public.notify_verification()
from public, anon, authenticated;

-- Aides RLS : évaluées avec le rôle de l'appelant, donc nécessaires aux
-- utilisateurs connectés, mais d'aucune utilité pour les visiteurs.
revoke execute on function
  public.can_read_event(uuid),
  public.can_edit_event(uuid),
  public.is_event_admin(uuid),
  public.in_conversation(uuid)
from public, anon;

-- is_admin() reste ouverte à anon : la politique de lecture publique de
-- creator_profiles l'évalue pour les visiteurs (elle renvoie alors false).
