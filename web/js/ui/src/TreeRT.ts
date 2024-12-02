class TreeRT {
    private tree: any;

    constructor(tree) {
        this.tree = tree;
    }

    render(elem, id, data) {
        this.tree.rander({
            elem: elem,
            data: data,
            id: id,

        })
    }

,

    getChecked() {
        return this.tree.getChecked('test');
    }
}

export default TreeRT;