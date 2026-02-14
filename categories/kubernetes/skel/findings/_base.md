```{=latex}
% {{ MANUAL_EDIT_WARNING }}
```

{% block retest %}{% endblock %}

{% if self.retest() | trim %}
#### Original Description
{% endif %}

{% block description required %}{% endblock %}

{% if self.likelihood() | trim %}
#### Likelihood
{% endif %}

{% block likelihood %}{% endblock %}

{% if self.likelihood() | trim %}
#### Impact
{% endif %}

{% block impact %}{% endblock %}

{% if self.likelihood() | trim %}
#### Recommendation
{% endif %}

{% block recommendation %}{% endblock %}

{% if self.likelihood() | trim %}
#### Reference
{% endif %}

{% block reference %}{% endblock %}
