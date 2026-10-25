# Activer les comptes Hibi (une seule fois)

1. **SQL Editor** : coller `schema-v4-comptes.sql`, cliquer sur Run.
2. **Authentication > Sign In / Providers > Email** : Email activé, « Confirm email » activé, **Email OTP Length = 6**.
3. **Authentication > URL Configuration** : Site URL = `https://pascaltea.github.io/vivace/`.
4. **Authentication > Emails > Templates** : dans « Confirm signup » ET « Magic Link », remplacer le contenu par le modèle ci-dessous (le code `{{ .Token }}` doit y figurer).
5. Pour un usage réel : **Authentication > Emails > SMTP Settings**, brancher un service d'envoi (Resend, Brevo…). L'envoi intégré de Supabase est limité à quelques e-mails par heure.

## Modèle d'e-mail

Objet : `Votre code Hibi : {{ .Token }}`

```html
<div style="font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;max-width:420px;margin:0 auto;padding:32px 24px;color:#1D1D1F">
  <p style="font-size:15px;color:#66666B;margin:0 0 8px">Hibi 日々</p>
  <p style="font-size:17px;margin:0 0 24px">Voici votre code pour vous connecter :</p>
  <p style="font-size:40px;letter-spacing:10px;font-weight:600;margin:0 0 24px">{{ .Token }}</p>
  <p style="font-size:15px;color:#66666B;margin:0">Il est valable une heure. Si vous n'avez rien demandé, ignorez simplement cet e-mail.</p>
</div>
```
