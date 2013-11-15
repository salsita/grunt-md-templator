
<% _.forEach(children, function(section) { %>

<section id="<%= section.id %>">

  <%= section.body %>

  <icon_nav/>

  <% _.forEach(section.children, function(article) { %>

    <article id="<%= article.id %>">
      <%= article.body %>
    </article><% })
  %>

</section><%
}) %>
