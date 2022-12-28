select * from pg_proc where proname = 'event_began';

SELECT
    pg_get_functiondef((
            SELECT
                oid FROM pg_proc
            WHERE
                proname = 'event_began'));

select proname from pg_proc where pronamespace = (select oid from pg_namespace where nspname = 'useraccesscontrol')

drop table  rlsepp.useraccesscontrol.sso

CREATE TABLE rlsepp.public.event (
	eid serial NOT NULL,
	created_by varchar(80) NOT NULL,
	transaction_tag varchar(80),
	tagid bigint NOT NULL,
	"action" action,
	exchange varchar(80),
	fromexchange varchar(80),
	address varchar(255),
	"cost" float8,
	costtype varchar(80),
	amount float8 NOT NULL,
	amounttype varchar(80),
	symbol varchar(80),
	fee float8,
	price float8,
	pricetype varchar(80),
	fullfilled float8,
	remaining float8,
	orderbookid bigint,
	datetime timestamptz,
	fullfilled_datetime timestamptz,
	cantmove varchar(8192),
	error_exception_api varchar(512),
	tid bigint,
	success bool,
	status varchar(20),
	txid varchar(255),
	created timestamptz,
	PRIMARY KEY (eid)
);
CREATE UNIQUE INDEX event_transaction_tag_tagid_key ON public.event USING btree (transaction_tag, tagid);

CREATE TABLE rlsepp.useraccesscontrol.sso (
	ssoid serial NOT NULL,
	useremail varchar(255),
	guserid varchar(255),
	gusername varchar(255),
	guseremail varchar(255),
	guserimageurl varchar(8192),
	PRIMARY KEY (ssoid)
);
CREATE UNIQUE INDEX sso_email_key ON useraccesscontrol.sso USING btree (useremail, guseremail);

CREATE OR REPLACE FUNCTION public.walletstatus_modified()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	declare 
    BEGIN

CREATE OR REPLACE FUNCTION public.audittransaction()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	declare 
	  wsHasTo int;
  	  wsHasFrom int;
	  wsTo typewalletstatus;
  	  wsFrom typewalletstatus;
  	  Nsymbol varchar;
    BEGIN
    	Nsymbol := split_part(NEW.amountType, '/', 1);
--    select count(exchange) from walletstatus where exchange='yobits'
        -- Check that empname and salary are given
        IF NEW.action = 'move' THEN
        	wsHasTo := (select count(exchange) from walletstatus where exchange=NEW.exchange);
        	wsHasFrom := (select count(exchange) from walletstatus where exchange=NEW.fromExchange);
        	wsTo := 'Online';
        	wsFrom := 'Online';
        	wsTo := (select status from walletstatus where exchange=NEW.exchange and symbol=Nsymbol);
        	wsFrom := (select status from walletstatus where exchange=NEW.fromExchange and symbol=Nsymbol);
        	if wsTo != 'Online' and wsHasTo > 0 then
	            RAISE EXCEPTION 'walletstatus for % to % is %', Nsymbol, NEW.exchange, wsTo;
	        end if; 
           	if wsHasFrom > 0 and wsFrom != 'Online' then
	            RAISE EXCEPTION 'walletstatus for % to % is %', Nsymbol, NEW.fromExchange, wsFrom;
	        end if; 
        END IF;
        RETURN NEW;
    END;
$function$



--    select count(exchange) from walletstatus where exchange='yobits'
        -- Check that empname and salary are given
        IF NEW.status != OLD.status THEN
        	NEW.previous := OLD.status;
        	NEW.modified := NEW.updated;
        END IF;
        RETURN NEW;
    END;
$function$




select proname from pg_proc where pronamespace = (select oid from pg_namespace where nspname = 'public')
select * from pg_proc

CREATE OR REPLACE FUNCTION public.audittransaction()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
	declare 
	  wsHasTo int;
  	  wsHasFrom int;
	  wsTo typewalletstatus;
  	  wsFrom typewalletstatus;
  	  Nsymbol varchar;
    BEGIN
    	Nsymbol := split_part(NEW.amountType, '/', 1);
--    select count(exchange) from walletstatus where exchange='yobits'
        -- Check that empname and salary are given
        IF NEW.action = 'move' THEN
        	wsHasTo := (select count(exchange) from walletstatus where exchange=NEW.exchange);
        	wsHasFrom := (select count(exchange) from walletstatus where exchange=NEW.fromExchange);
        	wsTo := 'Online';
        	wsFrom := 'Online';
        	wsTo := (select status from walletstatus where exchange=NEW.exchange and symbol=Nsymbol);
        	wsFrom := (select status from walletstatus where exchange=NEW.fromExchange and symbol=Nsymbol);
        	if wsTo != 'Online' and wsHasTo > 0 then
	            RAISE EXCEPTION 'walletstatus for % to % is %', Nsymbol, NEW.exchange, wsTo;
	        end if; 
           	if wsHasFrom > 0 and wsFrom != 'Online' then
	            RAISE EXCEPTION 'walletstatus for % to % is %', Nsymbol, NEW.fromExchange, wsFrom;
	        end if; 
        END IF;
        RETURN NEW;
    END;
$function$

CREATE OR REPLACE FUNCTION useraccesscontrol.sso.register()



drop function useraccesscontrol.googlesso
CREATE OR REPLACE FUNCTION useraccesscontrol.googlesso (Pguserid varchar, Pgusername varchar, Pguseremail varchar, Pguserimageurl varchar, OUT Pssoid integer)
 LANGUAGE plpgsql
AS $function$
BEGIN


INSERT INTO useraccesscontrol.sso ("useremail", "guserid", "gusername", "guseremail", "guserimageurl")
 VALUES (Pguseremail, Pguserid, Pgusername, Pguseremail, Pguserimageurl)
ON CONFLICT("useremail", "guseremail") DO UPDATE 
 SET gusername = excluded.gusername, guserimageurl=excluded.guserimageurl, guserid=excluded.guserid
 ;
  
Pssoid := (select ssoid from useraccesscontrol.sso where useremail=Pguseremail);

RAISE LOG 'uac.googlesso % => ssoid %', Pguseremail, Pssoid;

END
$function$

select * from useraccesscontrol.sso 

--"guseremail":"nathaniel.lally@gmail.com","guserid":"105574542004895483207","guserimageurl":"https:\/\/lh3.googleusercontent.com\/a-\/AOh14Gic4Gm55u91Cmqg5vyHalVDUlDoQSHlJMmpR20g=s96-c","gusername":"Nathaniel%20Lally"
select useraccesscontrol.googlesso('105574542004895483207', 'Nathaniel%20Lally', 'nathaniel.lally@gmail.com', 'test');


INSERT INTO useraccesscontrol.sso ("useremail", "guserid", "gusername", "guseremail", "guserimageurl") 
       VALUES ($1, $2, $3, $4, $5)
ON CONFLICT("useremail", "guseremail") DO NOTHING RETURNING ssoid;

CREATE TABLE rlsepp.useraccesscontrol.sso (
	userid serial NOT NULL,
	username varchar(255),
	useremail varchar(255),
	guserid varchar(255),
	gusername varchar(255),
	guseremail varchar(255),
	guserimageurl varchar(8192),
	PRIMARY KEY (userid)
);





