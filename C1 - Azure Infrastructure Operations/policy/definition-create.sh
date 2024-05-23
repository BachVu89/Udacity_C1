az policy definition create --name tagging-policy --subscription "required tags" \
--params "{ \"tagName\": { \"type\": \"String\", \"metadata\": { \"displayName\": \"Tag Name\", \"description\": \"Name of the tag is required, such as 'environment'\" } } }" \
--rules "{\"if\": { \"field\": \"tags\", \"exists\": \"false\" }, \"then\": { \"effect\": \"deny\" }}"
