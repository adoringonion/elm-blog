const fs = require('fs');
const glob = require('glob');
const parser = require('node-html-parser')

glob.glob('dist/blog/post/*/index.html', (err, files) => {
    files.forEach(file => {
        console.log(file);
        const html = fs.readFileSync(file, 'utf8');
        const root = parser.parse(html);

        root.querySelector('#utterances').insertAdjacentHTML('afterbegin', '<script src="https://utteranc.es/client.js" repo="adoringonion/utteranc_repo" issue-term="pathname" theme="github-light" crossorigin="anonymous" async> </script>');
        fs.writeFileSync(file, root.toString());
    });
});
