CREATE TABLE IF NOT EXISTS 'sentences' (
    'id' INTEGER PRIMARY KEY AUTOINCREMENT,
    'person' TEXT NOT NULL,
    'sentence' TEXT NOT NULL
)

INSERT INTO sentences (person, sentence) VALUES 
    ('mao','ben maoyum'),
    ('mac','arı gibi ucar'),
    ('RTE','dunya besten buyuktur')

INSERT INTO sentences (person, sentence) VALUES 
('Byron','Mutluluğu tatmanın tek çaresi, onu paylaşmaktır'),
('Eflatun', 'Küçük şeylere gereğinden çok önem verenler, elinden büyük iş gelmeyenlerdir'),
('Oprah Winfrey','Her şeyi elde edebilirsin ama aynı anda değil');
