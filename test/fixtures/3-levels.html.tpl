<% _.forEach(children, function(main) { %>

<div id="<%= main.id %>">

  <%= main.content %>

  <icon_nav/>

  <% _.forEach(main.children, function(section) { %>

    <section id="<%= section.id %>">
      <%= section.content %>

      <% _.forEach(section.children, function(article) { %>
        <article id="<%= article.id %>">
          <%= article.content %>
        </article>
      <% }) %>

    </section><% })
  %>

</div><%
}) %>
