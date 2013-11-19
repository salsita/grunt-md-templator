
<% _.forEach(children, function(section) { %>

<section id="<%= section.id %>">

  <%= section.header %>

  <%= section.body %>

  <icon_nav/>

  <% _.forEach(section.children, function(article) { %>

    <article id="<%= article.id %>">
      <%= article.content %>
    </article><% })
  %>

</section><%
}) %>
