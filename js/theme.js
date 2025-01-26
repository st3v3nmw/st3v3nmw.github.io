document.addEventListener('DOMContentLoaded', () => {
    const codeBlocks = document.querySelectorAll('pre > code');

    codeBlocks.forEach(codeBlock => {
        const copyButton = document.createElement('button');
        copyButton.innerHTML = '<i class="fa-solid fa-copy"></i> Copy';
        copyButton.classList.add('copy-btn');

        copyButton.addEventListener('click', () => {
            const code = codeBlock.textContent;
            navigator.clipboard.writeText(code).then(() => {
                copyButton.innerHTML = '<i class="fa-solid fa-check"></i> Copied!';
                setTimeout(() => {
                    copyButton.innerHTML = '<i class="fa-solid fa-copy"></i> Copy';
                }, 2000);
            });
        });

        codeBlock.parentNode.style.position = 'relative';
        codeBlock.parentNode.appendChild(copyButton);
    });
});
