CREATE DATABASE exerc_campeonato
GO
USE exerc_campeonato

CREATE TABLE times(
codigo INT IDENTITY NOT NULL, 
nome   VARCHAR(100) NOT NULL, 
sigla  CHAR(3) NOT NULL
PRIMARY KEY (codigo)
)

CREATE TABLE jogos(
timeA	 INT NOT NULL,
timeB	 INT NOT NULL,
golsA	 INT,
golsB	 INT,
datahora DATETIME NOT NULL
PRIMARY KEY(timeA,timeB)
FOREIGN KEY (timeA) REFERENCES times(codigo),
FOREIGN KEY (timeB) REFERENCES times(codigo)
)

CREATE TABLE campeonato(
codtime	INT NOT NULL,
jogos		INT,
vitorias	INT,
empates		INT,
derrotas	INT,
golspro		INT,
golscontra	INT
PRIMARY KEY (codtime)
FOREIGN KEY (codtime) REFERENCES times(codigo)
)

--Insere no campeonato os times que são registrados
CREATE TRIGGER t_inseretimenocampeonato ON times
FOR INSERT
AS
BEGIN
	DECLARE @cod INT

	SELECT @cod = codigo FROM INSERTED

	INSERT INTO campeonato VALUES (@cod,0,0,0,0,0,0)
END

INSERT INTO times VALUES ('Barcelona','BAR')
INSERT INTO times VALUES ('Celta e Vigo','CEL')
INSERT INTO times VALUES ('Málaga','MAL')
INSERT INTO times VALUES ('Real Madrid','RMA')

--Procedure para inserir os adversários e a data/hora do jogo
CREATE PROCEDURE sp_inserejogo(@timeA INT,@timeB INT, @datahora DATETIME)
AS
	DECLARE  @verifica_tA INT,
			 @verifica_tB INT
	
	SET @verifica_tA = (SELECT COUNT(*) FROM times WHERE codigo = @timeA)
	SET @verifica_tB = (SELECT COUNT(*) FROM times WHERE codigo = @timeB)

	IF(@verifica_tA = 1 AND @verifica_tB = 1)
	BEGIN
		INSERT INTO jogos VALUES (@timeA,@timeB,NULL,NULL,@datahora)
	END
	ELSE
	BEGIN
		RAISERROR('Erro',16,1)
	END

EXEC sp_inserejogo 1, 2, '22-04-2013 15:00' 
EXEC sp_inserejogo 1, 3, '29-04-2013 15:00' 
EXEC sp_inserejogo 1, 4, '06-05-2013 15:00' 

EXEC sp_inserejogo 2, 1, '25-04-2013 15:00'
EXEC sp_inserejogo 2, 3, '02-04-2013 15:00' 
EXEC sp_inserejogo 2, 4, '09-05-2013 15:00' 

EXEC sp_inserejogo 3, 1, '12-05-2013 15:00' 
EXEC sp_inserejogo 3, 2, '15-05-2013 15:00' 
EXEC sp_inserejogo 3, 4, '18-05-2013 15:00' 

EXEC sp_inserejogo 4, 1, '23-05-2013 15:00' 
EXEC sp_inserejogo 4, 2, '27-05-2013 15:00' 
EXEC sp_inserejogo 4, 3, '31-05-2013 15:00' 

--Atualiza campos do campeonato quando inserir os gols de um jogo
CREATE TRIGGER t_atualizacampeonato ON jogos
FOR UPDATE
AS
BEGIN
	DECLARE @timeA INT,
			@timeB INT,
			@golsA  INT,
			@golsB  INT

	SELECT @timeA = timeA, @timeB = timeB, @golsA = golSA, @golsB = golSB FROM INSERTED

	IF (@golsA > @golsB)BEGIN --GANHOU
		UPDATE campeonato SET jogos += 1, vitorias += 1, golspro += @golsA, golscontra += @golsB WHERE codtime = @timeA 
		UPDATE campeonato SET jogos += 1, derrotas += 1, golspro += @golsB, golscontra += @golsA WHERE codtime = @timeB 
	END
	ELSE
	BEGIN
		IF (@golsA < @golsB)BEGIN --PERDEU
			UPDATE campeonato SET jogos += 1, derrotas += 1, golspro += @golsA, golscontra += @golsB WHERE codtime = @timeA 
			UPDATE campeonato SET jogos += 1, vitorias += 1, golspro += @golsB, golscontra += @golsA WHERE codtime = @timeB 
		END
		ELSE
		BEGIN --EMPATOU
			UPDATE campeonato SET jogos += 1, empates += 1, golspro += @golsA, golscontra += @golsB WHERE codtime = @timeA 
			UPDATE campeonato SET jogos += 1, empates += 1, golspro += @golsB, golscontra += @golsA WHERE codtime = @timeB 
		END
	END
END

--FUNCTION que retorna uma tabela com a PONTUAÇÃO  de cada time
CREATE FUNCTION fn_campeonato() RETURNS @tabela TABLE(
Sigla_Time  CHAR(3),
Jogos       INT,
Vitorias    INT,
Empates     INT,
Derrotas    INT,
Gols_Pro    INT,
Gols_Contra INT,
Pontos      INT
)
AS
BEGIN
	INSERT @tabela(Sigla_Time,Jogos,Vitorias,Empates,Derrotas,Gols_Pro,Gols_Contra)
		SELECT t.sigla, c.jogos, c.vitorias, c.empates, c.derrotas, c.golspro, c.golscontra 
		FROM times t INNER JOIN campeonato c ON t.codigo = c.codtime 

	UPDATE @tabela SET Pontos = (Vitorias*3) + Empates

	RETURN 
END

UPDATE jogos SET golsA = 1, golsB = 2 WHERE datahora = '22-04-2013 15:00'
UPDATE jogos SET golsA = 3, golsB = 0 WHERE datahora = '29-04-2013 15:00'
UPDATE jogos SET golsA = 1, golsB = 1 WHERE datahora = '06-05-2013 15:00'

UPDATE jogos SET golsA = 2, golsB = 0 WHERE datahora = '25-04-2013 15:00'
UPDATE jogos SET golsA = 0, golsB = 0 WHERE datahora = '02-04-2013 15:00'
UPDATE jogos SET golsA = 3, golsB = 2 WHERE datahora = '09-05-2013 15:00' 

UPDATE jogos SET golsA = 1, golsB = 1 WHERE datahora = '12-05-2013 15:00' 
UPDATE jogos SET golsA = 1, golsB = 3 WHERE datahora = '15-05-2013 15:00' 
UPDATE jogos SET golsA = 1, golsB = 2 WHERE datahora = '18-05-2013 15:00'

UPDATE jogos SET golsA = 2, golsB = 1 WHERE datahora = '23-05-2013 15:00' 
UPDATE jogos SET golsA = 3, golsB = 3 WHERE datahora = '27-05-2013 15:00' 
UPDATE jogos SET golsA = 1, golsB = 1 WHERE datahora = '31-05-2013 15:00' 


SELECT * FROM jogos
SELECT * FROM campeonato
SELECT * FROM fn_campeonato()