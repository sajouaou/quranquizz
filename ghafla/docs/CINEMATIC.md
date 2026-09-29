# Cinématique d'ouverture

Durée : environ deux minutes. On peut la passer à tout moment (Échap, Entrée ou double clic).
Aucun visage n'est jamais montré : les hommes sont des silhouettes en contre-jour, et les mains, le Mushaf et la lumière font le récit.
Le code est dans `scripts/cinematic/cinematic.gd` ; le personnage est `person_rig.gd`
(squelette à deux os par membre, dessiné en code).

| # | Plan | Ce qu'on voit | Texte |
|---|---|---|---|
| 1 | Carton | Fond noir | « Une nuit ordinaire. » |
| 2 | Chambre, nuit | Le premier homme lit le Mushaf assis au bord du lit, à la lueur d'une lampe, et tourne une page lentement. | |
| 3 | | Il ferme le Mushaf et le tient contre lui, se lève, le pose sur son support, plus haut que lui. | |
| 4 | | Il éteint la lampe, se couche, tire la couverture. La lune brille à la fenêtre. | |
| 5 | Fondu | Autre chambre, mêmes meubles, même Mushaf sur son support. | « Une autre chambre. » |
| 6 | | Le second homme entre, s'arrête devant le Mushaf, le regarde, hésite, se détourne. | |
| 7 | | Il s'assoit au bord du lit, se couche sans l'avoir ouvert. | |
| 8 | Aube | Le ciel de la fenêtre passe du bleu de nuit au rose et à l'or ; un rayon de soleil traverse la pièce et remonte sur le lit. | « Le temps passe… » |
| 9 | Réveil | Il se redresse en sursaut (éclair de lumière, battement de cœur). | « Astaghfirullah… le soleil ?! » |
| 10 | | | « Fajr… j'ai raté Fajr. » |
| 11 | | Il se lève, va prendre le Mushaf sur son support. | « Le Mushaf… Pourquoi est-il si léger ? » |
| 12 | Gros plan | Le Mushaf ouvert : l'encre quitte les lignes en particules dorées, les pages blanchissent. | « Les mots… ils s'en vont. » |
| 13 | | Les pages défilent, toutes blanches. | « Les pages… elles sont vides. » |
| 14 | | Retour à la chambre, la lumière dorée envahit l'écran. | « Cette lumière, derrière la porte… » |

Pour ne pas répéter ce dernier texte, le jeu commence par un murmure différent (« Je ne comprends pas ce qui m'arrive. Mais je dois sortir. »).

## Choix de réalisation

- Le premier homme lit avec soin, range le livre en hauteur et l'éteint avec calme : ce contraste, sans un mot, fait le message.
- Le second n'est pas montré comme méprisable : il hésite, il est fatigué. Le texte est à la première personne, c'est lui qui se reprend.
- Le mot « Astaghfirullah » est une formule de repentir courante ; il n'est pas cité d'un texte sacré.
- Les pages qui blanchissent sont montrées visuellement (l'encre s'envole, le papier s'éclaircit), comme demandé.

# Cinématique du chapitre 2 (`cinematic2.gd`)

Durée : environ 1 minute 30, passable de la même façon. Toujours des silhouettes sans visage ; l'adulte est là en spectateur (transparent).

| # | Plan | Ce qu'on voit | Texte |
|---|---|---|---|
| 1 | Carton | Fond noir | « Un autre soir. » |
| 2 | Chambre, soir | Un enfant (la même silhouette, plus petite) empile des cubes de bois sur le tapis. | « Il y a très longtemps… » |
| 3 | | L'adulte apparaît près de la table, transparent. | « Je me souviens de ce soir. » |
| 4 | | Le père entre : « Mon fils, viens. C'est l'heure de la prière. » L'enfant fait comme s'il n'entendait pas. | « Encore un peu… » |
| 5 | | La mère (silhouette voilée) entre : « Mon fils, aide-moi un instant. » Il continue. Ils repartent doucement, sans un mot de reproche. | |
| 6 | | Le rêve se défait : cubes et enfant s'effacent, la lumière baisse. | « C'était moi. » |
| 7 | Page | La page de Luqman apparaît, entourée de lumière. | « Une page… ces conseils que j'avais entendus. » |

Choix : les parents sont doux, l'enfant n'est pas moqué (c'est un enfant) ; c'est l'adulte qui se regarde et qui se reprend, jamais un tiers qui le juge.
