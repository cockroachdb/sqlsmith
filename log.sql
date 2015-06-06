-- schema for --log-to

create table instance (
    id bigserial primary key,
    rev text,
    target text,
    hostname text,

    -- not referenced by sqlsmith:
    t timestamptz default now(),
    client inet default inet_client_addr()
);

comment on table instance is 'details about an sqlsmith instance';

create table error (
    id bigint references instance(id),
    msg text,    -- error message
    query text,  -- failed query
    target text, -- conninfo of the target
    
    -- not referenced by sqlsmith:
    t timestamptz default now()
);

comment on table error is 'observed errors';

create view base_error as
       select id, (regexp_split_to_array(msg,'\n'))[1] as error, query from error;

comment on view base_error is 'like error, but truncate msg to first line';

create view report as
       select count(1), error from base_error group by 2 order by count desc;

comment on view report is 'same report as sqlsmith''s verbose output';

create view instance_activity as
       select hostname, target, max(e.t)
       	      from instance i join error e on (i.id = e.id)
	      group by hostname, target
              order by max desc;

comment on view instance_activity is 'time of last error message from instance';
