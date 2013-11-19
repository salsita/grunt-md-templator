<% _.forEach(children, function(main) { %>

<div id="<%= main.id %>">

  <%= main.body %>

  <icon_nav/>

  <% _.forEach(main.children, function(section) { %>

    <section id="<%= section.id %>">
      <%= section.body %>

      <% _.forEach(section.children, function(article) { %>
        <article id="<%= article.id %>">
          <%= article.body %>
        </article>
      <% }) %>

    </section><% })
  %>

</div><%
}) %>
