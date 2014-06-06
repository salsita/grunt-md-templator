<% _.forEach(children, function(main) { %>

<div id="<%= main.id %>">

  <%= main.content %>

  <% _.forEach(main.children, function(section) { %>

    <section id="<%= section.id %>">
      <%= section.body %>

      <% if (section.blocks.front && section.blocks.back) { %>

        <div class="I-am-the-front-block">
          <%= section.blocks.front.html %>
        </div>
        <div class="I-am-the-second-block">
          <%= section.blocks.back.html %>
        </div>

      <% } else { %>

        <% _.forEach(section.children, function(article) { %>
          <article id="<%= article.id %>">
            <%= article.content %>
          </article>
        <% }) %>

      <% } %>

    </section><% })
  %>

</div><%
}) %>
