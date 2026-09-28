// Stories told in the Qur'an (Qaṣaṣ al-Qur'ān), used by the story mode.
//
// Content rules (see docs/GAME_DESIGN.md):
// - summaries only relate what the verses say; details from outside the Qur'an are
//   limited to what authentic Sunnah / tafsir state, and are marked as such;
// - lessons give an approximate MEANING of a verse with its reference, never a
//   translation presented as the Qur'an itself, and never Arabic text typed by hand;
// - no pictures of prophets or people: stories are represented by text and recitation only.

export type StoryGroup = 'prophets' | 'faith' | 'wisdom';

export interface Story {
  id: string;
  group: StoryGroup;
  title: string;
  person?: string;
  honorific?: string;
  surah: number;
  from: number; // first ayah (1-based, inclusive)
  to: number; // last ayah (inclusive)
  summary: string;
  lesson: { meaning: string; ref: string };
}

export const STORY_GROUPS: { id: StoryGroup; title: string; subtitle: string }[] = [
  { id: 'prophets', title: 'Les prophètes', subtitle: 'Leur appel, leurs épreuves, leur confiance en Allah' },
  { id: 'faith', title: 'Figures de foi', subtitle: 'Des croyants que le Coran donne en exemple' },
  { id: 'wisdom', title: 'Sagesse et rappels', subtitle: 'Des récits pour réfléchir' },
];

const AS = 'عليه السلام';

export const STORIES: Story[] = [
  {
    id: 'adam', group: 'prophets', title: 'Adam et le repentir', person: 'Adam', honorific: AS,
    surah: 2, from: 30, to: 39,
    summary: "Allah annonce aux anges qu'Il va établir un khalife sur terre. Il enseigne à Adam les noms de toutes choses, puis ordonne aux anges de se prosterner devant lui : tous obéissent, sauf Iblis, par orgueil. Trompés par Satan, Adam et son épouse sortent du Jardin ; Adam reçoit alors de son Seigneur des paroles de repentir, et Allah accepte son repentir.",
    lesson: { meaning: 'Adam reçut de son Seigneur des paroles, et Allah accepta son repentir : c’est Lui qui accueille le repentir, le Très Miséricordieux.', ref: '2:37' },
  },
  {
    id: 'nuh', group: 'prophets', title: "L'appel patient de Nuh", person: 'Nuh', honorific: AS,
    surah: 71, from: 1, to: 28,
    summary: "Nuh appelle son peuple, de nuit comme de jour, en public comme en secret, à adorer Allah seul et à implorer Son pardon. Mais plus il les appelle, plus ils se détournent, se bouchant les oreilles et s'enveloppant de leurs vêtements. Nuh se tourne alors vers son Seigneur par l'invocation.",
    lesson: { meaning: 'Implorez le pardon de votre Seigneur, car Il est Grand Pardonneur : Il enverra sur vous du ciel une pluie abondante.', ref: '71:10-11' },
  },
  {
    id: 'hud', group: 'prophets', title: 'Hud et le peuple de ʿĀd', person: 'Hud', honorific: AS,
    surah: 11, from: 50, to: 60,
    summary: "Hud appelle son peuple, les ʿĀd, à adorer Allah seul et à se repentir. Ils refusent et le défient. Hud place sa confiance en Allah, son Seigneur et le leur. Par une miséricorde d'Allah, Hud et les croyants sont sauvés, tandis que ʿĀd, qui avaient renié les signes de leur Seigneur, sont anéantis.",
    lesson: { meaning: 'Je place ma confiance en Allah, mon Seigneur et votre Seigneur.', ref: '11:56' },
  },
  {
    id: 'salih', group: 'prophets', title: 'Salih et la chamelle', person: 'Salih', honorific: AS,
    surah: 11, from: 61, to: 68,
    summary: "Salih appelle les Thamud à adorer Allah, qui les a créés de la terre et les y a établis. Une chamelle leur est donnée comme signe, avec l'ordre de la laisser paître en paix. Ils la tuent ; Salih et les croyants sont sauvés, et les injustes sont saisis par le Cri.",
    lesson: { meaning: 'C’est Lui qui vous a créés de la terre et vous l’a fait habiter. Implorez donc Son pardon, puis revenez à Lui.', ref: '11:61' },
  },
  {
    id: 'ibrahim', group: 'prophets', title: 'Ibrahim et les idoles', person: 'Ibrahim', honorific: AS,
    surah: 21, from: 51, to: 70,
    summary: "Le jeune Ibrahim interroge son père et son peuple sur les statues qu'ils adorent. Il les brise, sauf la plus grande, pour les amener à réfléchir. Condamné au feu, il est sauvé par l'ordre d'Allah : le feu devient fraîcheur et paix pour lui.",
    lesson: { meaning: 'Ô feu, sois fraîcheur et paix pour Ibrahim !', ref: '21:69' },
  },
  {
    id: 'yusuf', group: 'prophets', title: 'Yusuf, le plus beau des récits', person: 'Yusuf', honorific: AS,
    surah: 12, from: 4, to: 101,
    summary: "Yusuf voit en rêve onze astres, le soleil et la lune se prosterner devant lui. Jaloux, ses frères le jettent au fond d'un puits ; il est recueilli puis vendu en Égypte. Éprouvé, emprisonné injustement, il reste patient et fidèle à Allah, interprète le rêve du roi et devient responsable des réserves du pays. Ses frères viennent à lui : il leur pardonne et retrouve son père Yaʿqub.",
    lesson: { meaning: 'Quiconque craint Allah et patiente… Allah ne laisse pas perdre la récompense des bienfaisants.', ref: '12:90' },
  },
  {
    id: 'musa', group: 'prophets', title: 'Musa, du feu sacré à la mer', person: 'Musa', honorific: AS,
    surah: 20, from: 9, to: 79,
    summary: "Musa aperçoit un feu et y reçoit l'appel de son Seigneur, qui le charge d'aller vers Pharaon. Il demande à Allah de lui ouvrir la poitrine et de lui donner son frère Harun comme soutien. Face aux magiciens, la vérité triomphe et ceux-ci se prosternent en croyants. Allah sauve ensuite Musa et son peuple en leur ouvrant un chemin sec dans la mer.",
    lesson: { meaning: 'Seigneur, ouvre-moi ma poitrine, facilite-moi ma mission, et dénoue une attache de ma langue, afin qu’ils comprennent mes paroles.', ref: '20:25-28' },
  },
  {
    id: 'sulayman', group: 'prophets', title: 'Sulayman, la fourmi et la huppe', person: 'Sulayman', honorific: AS,
    surah: 27, from: 15, to: 44,
    summary: "Allah accorde la science à Dawud et Sulayman, et Sulayman comprend le langage des oiseaux. Entendant une fourmi avertir les siennes, il sourit et remercie son Seigneur. La huppe lui rapporte qu'une reine de Saba et son peuple se prosternent devant le soleil ; Sulayman lui écrit, et la reine finit par se soumettre, avec Sulayman, à Allah, Seigneur des mondes.",
    lesson: { meaning: 'Seigneur, inspire-moi de Te remercier pour le bienfait dont Tu m’as comblé, ainsi que mes parents, et d’accomplir le bien que Tu agrées.', ref: '27:19' },
  },
  {
    id: 'ayyub', group: 'prophets', title: "La patience d'Ayyub", person: 'Ayyub', honorific: AS,
    surah: 38, from: 41, to: 44,
    summary: "Éprouvé, Ayyub appelle son Seigneur. Allah lui ordonne de frapper le sol du pied : une eau fraîche jaillit pour se laver et boire. Allah lui rend sa famille, et autant avec elle, par miséricorde et comme rappel pour les gens doués d'intelligence.",
    lesson: { meaning: 'Nous l’avons trouvé endurant. Quel excellent serviteur ! Il revenait sans cesse vers Allah.', ref: '38:44' },
  },
  {
    id: 'yunus', group: 'prophets', title: 'Yunus dans les ténèbres', person: 'Yunus', honorific: AS,
    surah: 37, from: 139, to: 148,
    summary: "Yunus, l'un des messagers, s'enfuit vers un bateau chargé. Tiré au sort, il est jeté à la mer et avalé par un grand poisson. S'il n'avait pas été de ceux qui glorifient Allah, il y serait resté. Allah le rejette sur le rivage, fait pousser au-dessus de lui un plant de courge, puis l'envoie vers un peuple de cent mille personnes ou plus, qui crurent.",
    lesson: { meaning: 'Pas de divinité à part Toi ! Gloire à Toi ! J’étais vraiment du nombre des injustes.', ref: '21:87' },
  },
  {
    id: 'zakariya', group: 'prophets', title: "L'invocation de Zakariya", person: 'Zakariya', honorific: AS,
    surah: 19, from: 2, to: 15,
    summary: "Zakariya, âgé, invoque son Seigneur d'un appel discret : ses os se sont affaiblis, ses cheveux ont blanchi et sa femme est stérile. Allah lui annonce un fils nommé Yahya, un nom qu'Il n'avait donné à personne auparavant, et fait de Yahya un enfant pieux et bon envers ses parents.",
    lesson: { meaning: 'Je n’ai jamais été déçu en T’invoquant, ô mon Seigneur.', ref: '19:4' },
  },
  {
    id: 'maryam', group: 'faith', title: 'Maryam et la naissance de ʿIsa', person: 'Maryam', honorific: 'عليها السلام',
    surah: 19, from: 16, to: 33,
    summary: "Maryam se retire loin des siens ; l'ange (Jibril, selon le tafsir) lui apparaît et lui annonce un fils pur. Dans les douleurs de l'enfantement, près d'un palmier, Allah la réconforte par un ruisseau et des dattes fraîches. Revenue auprès des siens, elle désigne l'enfant, et ʿIsa parle dès le berceau : il est le serviteur d'Allah.",
    lesson: { meaning: 'Je suis le serviteur d’Allah. Il m’a donné le Livre et a fait de moi un prophète.', ref: '19:30' },
  },
  {
    id: 'kahf', group: 'faith', title: 'Les gens de la Caverne',
    surah: 18, from: 9, to: 26,
    summary: "Des jeunes gens croyants quittent leur peuple, qui associe à Allah, et se réfugient dans une caverne en implorant Sa miséricorde. Allah les plonge dans un sommeil de nombreuses années, puis les réveille ; l'un d'eux part discrètement acheter de la nourriture. Leur histoire devient un signe que la promesse d'Allah est vérité et que l'Heure viendra, sans aucun doute.",
    lesson: { meaning: 'Seigneur, accorde-nous de Ta part une miséricorde, et assure-nous la droiture dans notre affaire.', ref: '18:10' },
  },
  {
    id: 'luqman', group: 'faith', title: 'Les conseils de Luqman',
    surah: 31, from: 12, to: 19,
    summary: "Allah a donné la sagesse à Luqman. Il exhorte son fils : ne rien associer à Allah, se souvenir qu'Allah voit même le poids d'un grain de moutarde, accomplir la prière, ordonner le bien, patienter, ne pas marcher avec arrogance et baisser la voix. Au milieu de ses conseils, Allah rappelle le devoir de bonté envers les parents.",
    lesson: { meaning: 'Ô mon fils, n’associe rien à Allah, car l’association est vraiment une injustice énorme.', ref: '31:13' },
  },
  {
    id: 'talut', group: 'faith', title: 'Talut et Jalut',
    surah: 2, from: 246, to: 251,
    summary: "Les notables des Banu Israʾil demandent un roi pour combattre dans le sentier d'Allah ; Allah leur désigne Talut. Éprouvés par une rivière, seuls quelques-uns restent fidèles. Face à l'armée de Jalut, ils implorent Allah de leur accorder l'endurance, et Dawud tue Jalut.",
    lesson: { meaning: 'Combien de fois une troupe peu nombreuse a vaincu une troupe nombreuse, par la permission d’Allah ! Et Allah est avec les endurants.', ref: '2:249' },
  },
  {
    id: 'khidr', group: 'wisdom', title: 'Musa et le serviteur savant', person: 'Musa', honorific: AS,
    surah: 18, from: 60, to: 82,
    summary: "Musa voyage jusqu'au confluent des deux mers pour apprendre auprès d'un serviteur d'Allah qui a reçu une science venant de Lui (al-Khiḍr, selon la Sunna). Celui-ci perce une barque, tue un garçon, redresse un mur sans demander de salaire. Musa ne peut s'empêcher de questionner ; le serviteur lui révèle alors la sagesse cachée de chaque acte.",
    lesson: { meaning: 'Tu me trouveras patient, si Allah le veut, et je ne désobéirai à aucun de tes ordres.', ref: '18:69' },
  },
  {
    id: 'dhulqarnayn', group: 'wisdom', title: 'Dhul-Qarnayn',
    surah: 18, from: 83, to: 98,
    summary: "Allah donne à Dhul-Qarnayn la puissance sur terre et les moyens d'atteindre toute chose. Il voyage jusqu'au couchant, puis jusqu'au levant, en jugeant avec justice. Un peuple menacé par Yaʾjuj et Maʾjuj lui demande de l'aide : sans rien réclamer, il bâtit avec eux une barrière de fer et de cuivre fondu, puis attribue tout à la miséricorde de son Seigneur.",
    lesson: { meaning: 'Ceci est une miséricorde de mon Seigneur.', ref: '18:98' },
  },
  {
    id: 'jardin', group: 'wisdom', title: 'Les gens du jardin',
    surah: 68, from: 17, to: 33,
    summary: "Les propriétaires d'un jardin jurent d'en cueillir les fruits au petit matin, sans rien laisser aux pauvres et sans dire « si Allah le veut ». Pendant qu'ils dorment, le jardin est ravagé. Découvrant le désastre, ils reconnaissent leur injustice, se repentent et espèrent de leur Seigneur quelque chose de meilleur.",
    lesson: { meaning: 'Gloire à notre Seigneur ! Nous étions vraiment injustes.', ref: '68:29' },
  },
  {
    id: 'qarun', group: 'wisdom', title: 'Qarun et ses trésors',
    surah: 28, from: 76, to: 82,
    summary: "Qarun, du peuple de Musa, reçoit des trésors dont les clés pèsent à un groupe d'hommes forts. Les siens lui conseillent de ne pas s'enorgueillir et de rechercher la Demeure dernière ; il répond qu'il ne doit sa richesse qu'à son propre savoir. La terre l'engloutit avec sa demeure, et ceux qui l'enviaient comprennent leur erreur.",
    lesson: { meaning: 'Recherche, à travers ce qu’Allah t’a donné, la Demeure dernière, et n’oublie pas ta part de ce monde.', ref: '28:77' },
  },
  {
    id: 'fil', group: 'wisdom', title: "L'armée de l'éléphant",
    surah: 105, from: 1, to: 5,
    summary: "Une armée accompagnée d'éléphants (celle d'Abraha, selon le tafsir) marche contre la Kaʿba. Allah déjoue sa ruse en envoyant contre elle des oiseaux par volées, qui lui lancent des pierres d'argile, et la rend semblable à une paille mâchée. Selon les historiens, cela eut lieu l'année de la naissance du Prophète Muhammad ﷺ.",
    lesson: { meaning: 'N’as-tu pas vu comment ton Seigneur a agi envers les gens de l’éléphant ?', ref: '105:1' },
  },
];

export const storyLength = (story: Story) => story.to - story.from + 1;

export function findStory(id: string): Story | undefined {
  return STORIES.find((s) => s.id === id);
}
